# Course 02613: Wall heating! mini-project

This project investigates the performance of different numerical and parallel computing approaches for solving steady-state heat diffusion (Laplace equation) on building floorplans. It includes implementations using NumPy, multiprocessing, Numba JIT (CPU/GPU), and CuPy plus performance profiling and scalability analysis based on Amdahl’s law.

[DTU course 02613 - Python and high-performance computing, Spring 2026]

# NOTER
## Task 7: Numba JIT (CPU)

### 7a) Performance af Numba JIT
Vi kørte JIT-implementeringen (`simulate_task_7.py`) for et subset på 10 bygninger som et batch job på 1 kerne. 
* **Tidsforbrug for 10 bygninger (JIT):** 24 sekunder (ca. 2,4 sekunder pr. bygning).
* **Sammenligning med reference:** Reference-koden (fra Task 2) tog 113 sekunder for de samme 10 bygninger. Dette giver os en speed-up på ca. **4,7x**. Det demonstrerer tydeligt den massive fordel ved at "pakke" NumPy-operationer ud i simple loops, når man bruger Numbas JIT-kompiler.

### 7b) Forklaring af funktion og CPU Cache (Spatial Locality)
For at Numba kan optimere koden effektivt, er de oprindelige vektoriserede NumPy array-operationer blevet "pakket ud" til to nestede `for`-loops. Vi bruger et `u_old` array til at læse temperaturerne fra, mens vi skriver de nye gennemsnit til `u` arrayet. Dette sikrer, at vi ikke lader opdaterede værdier forurene de igangværende beregninger i samme tids-skridt (Jacobi-metoden).

**Hensyn til CPU Cache:**
NumPy arrays ligger gemt i hukommelsen som *C-contiguous* (row-major). Det betyder, at data i samme række ligger lige ved siden af hinanden i computerens RAM. For at udnytte CPU-cachen bedst muligt og sikre spatial locality, er koden struktureret således, at det yderste loop (`i`) itererer over rækkerne, og det inderste loop (`j`) itererer henover kolonnerne. Hvis vi havde byttet om på `i` og `j`, ville computeren konstant skulle hoppe rundt i hukommelsen (hvilket forårsager cache misses), hvilket ville have gjort eksekveringen markant langsommere.

### 7c) Estimeret tid for alle floorplans
[cite_start]Datasættet består af 4571 bygningstegninger[cite: 9]. Med vores Numba JIT-implementering tager det gennemsnitligt 2,4 sekunder pr. bygning.
* **Beregning:** 2,4 sekunder * 4571 bygninger = 10.970 sekunder.
* **Estimeret total tid:** Omkring 183 minutter (lidt over 3 timer) for at processere hele datasættet på en enkelt kerne.


## Task 8: Custom CUDA Kernel (Numba)

### 8.1) Beskrivelse af løsningen, kernel og helper-funktion
Vores løsning udnytter GPU'ens massive parallelisme ved at dedikere én tråd (thread) til hver eneste "pixel" i vores 514x514 grid. 
* **Kernel (`jacobi_kernel`):** Kernen udregner udelukkende én enkelt Jacobi-iteration for et specifikt 2D-koordinat `(i, j)`. Den tjekker om punktet er inden for rummet (vha. `interior_mask`), og beregner gennemsnittet af naboerne.
* **Helper-funktion (`jacobi`):** CPU'en opsætter hukommelsen. For at undgå segmenteringsfejl (en kendt udfordring med Numba CUDA og boolske arrays) konverterer vi masken til `int8` og sikrer, at arrays er C-contiguous. Vi allokerer arrays på GPU'en (`cuda.to_device`), definerer et thread-grid (16x16 threads per block), og kører et fast `for`-loop med 20.000 iterationer, hvor vi bytter om på memory-pointerne for at undgå unødvendig data-kopiering. Til sidst synkroniserer vi og trækker resultatet tilbage til hosten.

### 8.2) Performance sammenlignet med referencen
Vi kørte CUDA-løsningen for et subset på 10 bygninger på et V100 grafikkort (via `02613_2026` miljøet).
* **Tidsforbrug for 10 bygninger (CUDA):** 20 sekunder.
* **Sammenligning:** Reference-koden (Task 2) tog 113 sekunder. Vores CUDA-kernel er altså over **5,5 gange hurtigere** (20 sekunder mod 113). Dette er et massivt speed-up, især når man tager i betragtning, at CUDA-kernen er tvunget til at køre samtlige 20.000 iterationer pr. bygning uden early stopping (`atol` er fjernet).

### 8.3) Estimeret tid for alle floorplans
Med vores CUDA-implementering tager det ca. 20 sekunder for 10 bygninger, altså præcis 2,0 sekunder pr. bygning.
* **Beregning:** 2,0 sekunder * 4571 bygninger = 9142 sekunder.
* **Estimeret total tid:** Omkring 152 minutter (ca. 2,5 timer) for at processere hele datasættet sekventielt igennem GPU'en.

## Task 9: 

Vores målinger viser, at CuPy-implementeringen (på A100 GPU'en) er betydeligt hurtigere end den CPU-baserede reference-implementering. Mens reference-løsningen arbejder lineært gennem bygningerne, udnytter CuPy GPU'ens massive parallelisme ved at beregne temperaturfelter for hele nettet samtidigt.

Estimated time to process all floorplans:
Da vi har processeret en subset på 10 bygninger på ca. 17 sekunder (fra 10:37:25 til 10:37:42), svarer det til ca. 1,7 sekunder pr. bygning. For at behandle alle 4571 bygninger vil det estimerede tidsforbrug være:
4571 bygninger * 1,7 sekunder ≈ 7.770 sekunder, hvilket svarer til ca. 2,15 timer.
(Bemærk: Dette kan variere en smule afhængigt af kø-tid og belastning på GPU-noden).

Surprising findings:
Det mest overraskende var, at koden er ekstremt følsom over for det valgte GPU-miljø. Vi oplevede, at koden ikke kunne køre på gpuv100-noder grundet arkitektur-inkompatibilitet, men fungerede fejlfrit på gpua100. Desuden kræver CuPy et "opvarmnings-overhead" (first-time compilation), hvor den første kørsel tager længere tid end efterfølgende kald, hvilket vi har taget højde for i vores performance-analyse

## Task 10: Profiling the CuPy solution (nsys)

### What is the main issue regarding performance?
Hovedproblemet i en direkte CuPy-oversættelse af referencekoden er **Memory Allocation Overhead** (konstant tildeling af ny hukommelse). 

Referencekoden bruger *boolean indexing* til at opdatere temperaturerne:
`u_new_interior = u_new[interior_mask]`

På en CPU virker dette fint, men på en GPU er det en katastrofe i et loop, der kører 20.000 gange. Vores profileringsdata med `nsys` (vist i `out_task_10.txt`) bekræftede denne flaskehals: `cudaMalloc` stod for over **97%** af den samlede tid anvendt på CUDA-API kald. Dette indikerer, at GPU'en bruger uforholdsmæssigt meget tid og energi på hele tiden at allokere nye, midlertidige arrays i sin hukommelse frem for at lave selve varme-udregningerne.

### Try to fix it
For at eliminere dette overhead har vi refaktoreret koden til at bruge `cp.where()`. Dette fjerner behovet for at oprette nye, midlertidige arrays i hver iteration.

I stedet bruger vi funktionen `cp.where()`, som beregner de nye værdier og opdaterer arrayet direkte ("in-place") uden at ændre arrayets størrelse eller allokere ny hukommelse:

```python
# Optimeret løsning i simulate_task_10.py
u_new[1:-1, 1:-1] = cp.where(
    mask_cp,
    0.25 * (u_old[:-2, 1:-1] + u_old[2:, 1:-1] + u_old[1:-1, :-2] + u_old[1:-1, 2:]),
    u_old[1:-1, 1:-1]
)
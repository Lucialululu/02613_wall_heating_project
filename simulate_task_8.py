from os.path import join
import sys
import numpy as np
import math
from numba import cuda

def load_data(load_dir, bid):
    SIZE = 512
    u = np.zeros((SIZE + 2, SIZE + 2))
    u[1:-1, 1:-1] = np.load(join(load_dir, f"{bid}_domain.npy"))
    interior_mask = np.load(join(load_dir, f"{bid}_interior.npy"))
    return u, interior_mask

@cuda.jit
def jacobi_kernel(u_old, u_new, interior_mask):
    i, j = cuda.grid(2)
    rows, cols = u_old.shape
    
    if i < rows and j < cols:
        if i > 0 and i < rows - 1 and j > 0 and j < cols - 1:
            if interior_mask[i-1, j-1]:
                u_new[i, j] = 0.25 * (u_old[i-1, j] + u_old[i+1, j] + u_old[i, j-1] + u_old[i, j+1])
            else:
                u_new[i, j] = u_old[i, j]
        else:
            u_new[i, j] = u_old[i, j]

def jacobi(u, interior_mask, max_iter):
    rows, cols = u.shape

    u_contig = np.ascontiguousarray(u)
    mask_contig = np.ascontiguousarray(interior_mask).astype(np.int8)
    
    # Alloker arrays på GPU'en
    d_u_old = cuda.to_device(u_contig)
    d_u_new = cuda.to_device(u_contig)
    d_interior_mask = cuda.to_device(mask_contig)
    
    threadsperblock = (16, 16)
    blockspergrid_x = math.ceil(rows / threadsperblock[0])
    blockspergrid_y = math.ceil(cols / threadsperblock[1])
    blockspergrid = (blockspergrid_x, blockspergrid_y)
    
    for _ in range(max_iter):
        jacobi_kernel[blockspergrid, threadsperblock](d_u_old, d_u_new, d_interior_mask)
        # Byt rundt på pointerne (hurtigere end at kopiere data memory)
        d_u_old, d_u_new = d_u_new, d_u_old
        
    cuda.synchronize()
    
    return d_u_old.copy_to_host()

def summary_stats(u, interior_mask):
    u_interior = u[1:-1, 1:-1][interior_mask]
    mean_temp = u_interior.mean()
    std_temp = u_interior.std()
    pct_above_18 = np.sum(u_interior > 18) / u_interior.size * 100
    pct_below_15 = np.sum(u_interior < 15) / u_interior.size * 100
    return {
        'mean_temp': mean_temp,
        'std_temp': std_temp,
        'pct_above_18': pct_above_18,
        'pct_below_15': pct_below_15,
    }

if __name__ == '__main__':
    LOAD_DIR = '/dtu/projects/02613_2025/data/modified_swiss_dwellings/'
    with open(join(LOAD_DIR, 'building_ids.txt'), 'r') as f:
        building_ids = f.read().splitlines()

    if len(sys.argv) < 2:
        N = 1
    else:
        N = int(sys.argv[1])
    building_ids = building_ids[:N]

    all_u0 = np.empty((N, 514, 514))
    all_interior_mask = np.empty((N, 512, 512), dtype='bool')
    for i, bid in enumerate(building_ids):
        u0, interior_mask = load_data(LOAD_DIR, bid)
        all_u0[i] = u0
        all_interior_mask[i] = interior_mask

    MAX_ITER = 20_000

    all_u = np.empty_like(all_u0)
    for i, (u0, interior_mask) in enumerate(zip(all_u0, all_interior_mask)):
        # Bemærk: Vi sender ikke ABS_TOL med mere
        u = jacobi(u0, interior_mask, MAX_ITER)
        all_u[i] = u

    stat_keys = ['mean_temp', 'std_temp', 'pct_above_18', 'pct_below_15']
    print('building_id, ' + ', '.join(stat_keys))
    for bid, u, interior_mask in zip(building_ids, all_u, all_interior_mask):
        stats = summary_stats(u, interior_mask)
        print(f"{bid},", ", ".join(str(stats[k]) for k in stat_keys))

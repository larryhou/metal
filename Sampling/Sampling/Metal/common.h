//
//  common.h
//  Sampling
//
//  Created by LARRYHOU on 2020/2/20.
//  Copyright © 2020 LARRYHOU. All rights reserved.
//

#include <simd/simd.h>

#ifndef common_h
#define common_h

struct MetalUniforms {
    matrix_float4x4 model;
    matrix_float4x4 view;
    matrix_float4x4 projection;
};

#endif /* common_h */

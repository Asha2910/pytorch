# NOTE: This file is shared by internal and OSS BUCK build.
# These load paths point to different files in internal and OSS environment

load("//tools/build_defs:expect.bzl", "expect")
load("//tools/build_defs:fb_native_wrapper.bzl", "fb_native")
load("//tools/build_defs:fb_python_binary.bzl", "fb_python_binary")
load("//tools/build_defs:fb_python_library.bzl", "fb_python_library")
load("//tools/build_defs:fb_xplat_cxx_library.bzl", "fb_xplat_cxx_library")
load("//tools/build_defs:fbsource_utils.bzl", "is_arvr_mode")
load("//tools/build_defs:glob_defs.bzl", "subdir_glob")
load("//tools/build_defs:platform_defs.bzl", "APPLETVOS", "IOS", "MACOSX")
load("//tools/build_defs/windows:windows_flag_map.bzl", "windows_convert_gcc_clang_flags")
load(
    ":build_variables.bzl",
    "jit_core_headers",
)

def read_bool(section, field, default):
    # @lint-ignore BUCKRESTRICTEDSYNTAX
    value = read_config(section, field)
    if value == None:
        return default
    expect(
        value == "0" or value == "1",
        "{}.{} == \"{}\", wanted \"0\" or \"1\".".format(section, field, value),
    )
    return bool(int(value))

def is_oss_build():
    return read_bool("pt", "is_oss", False)

# for targets in caffe2 root path
ROOT = "//" if is_oss_build() else "//xplat/caffe2"

# for targets in subfolders
ROOT_PATH = "//" if is_oss_build() else "//xplat/caffe2/"

# a dictionary maps third party library name to fbsource and oss target
THIRD_PARTY_LIBS = {
    "FP16": ["//third-party/FP16:FP16", "//third_party:FP16"],
    "FXdiv": ["//third-party/FXdiv:FXdiv", "//third_party:FXdiv"],
    "XNNPACK": ["//third-party/XNNPACK:XNNPACK", "//third_party:XNNPACK"],
    "clog": ["//third-party/clog:clog", "//third_party:clog"],
    "cpuinfo": ["//third-party/cpuinfo:cpuinfo", "//third_party:cpuinfo"],
    "fmt": ["//third-party/fmt:fmt", "//third_party:fmt"],
    "glog": ["//third-party/glog:glog", "//third_party:glog"],
    "psimd": ["//third-party/psimd:psimd", "//third_party:psimd"],
    "pthreadpool": ["//third-party/pthreadpool:pthreadpool", "//third_party:pthreadpool"],
    "pthreadpool_header": ["//third-party/pthreadpool:pthreadpool_header", "//third_party:pthreadpool_header"],
    "pyyaml": ["//third-party/pyyaml:pyyaml", "//third_party:pyyaml"],
    "ruy": ["//third-party/ruy:ruy_xplat_lib", "//third_party:ruy_lib"],
    "typing-extensions": ["//third-party/typing-extensions:typing-extensions", "//third_party:typing-extensions"],
}

def get_third_party_lib(name):
    if name not in THIRD_PARTY_LIBS:
        fail("Cannot find thrid party library " + name + ", please register it in THIRD_PARTY_LIBS first!")
    return THIRD_PARTY_LIBS[name][1] if is_oss_build() else THIRD_PARTY_LIBS[name][0]

def get_pt_compiler_flags():
    return select({
        "DEFAULT": _PT_COMPILER_FLAGS + [
            "-std=gnu++17",  #to accomodate for eigen
        ],
        "ovr_config//compiler:cl": windows_convert_gcc_clang_flags(_PT_COMPILER_FLAGS),
    })

_PT_COMPILER_FLAGS = [
    "-frtti",
    "-Os",
    "-Wno-unknown-pragmas",
    "-Wno-write-strings",
    "-Wno-unused-variable",
    "-Wno-unused-function",
    "-Wno-deprecated-declarations",
    "-Wno-shadow",
    "-Wno-global-constructors",
    "-Wno-missing-prototypes",
]

# these targets are shared by internal and OSS BUCK
def define_buck_targets(
        feature = None,
        labels = []):
    fb_xplat_cxx_library(
        name = "th_header",
        header_namespace = "",
        exported_headers = subdir_glob([
            # TH
            ("aten/src", "TH/*.h"),
            ("aten/src", "TH/*.hpp"),
            ("aten/src", "TH/generic/*.h"),
            ("aten/src", "TH/generic/*.hpp"),
            ("aten/src", "TH/generic/simd/*.h"),
            ("aten/src", "TH/vector/*.h"),
            ("aten/src", "TH/generic/*.c"),
            ("aten/src", "TH/generic/*.cpp"),
            ("aten/src/TH", "*.h"),  # for #include <THGenerateFloatTypes.h>
            # THNN
            ("aten/src", "THNN/*.h"),
            ("aten/src", "THNN/generic/*.h"),
            ("aten/src", "THNN/generic/*.c"),
        ]),
        feature = feature,
        labels = labels,
    )

    fb_xplat_cxx_library(
        name = "aten_header",
        header_namespace = "",
        exported_headers = subdir_glob([
            # ATen Core
            ("aten/src", "ATen/core/**/*.h"),
            ("aten/src", "ATen/ops/*.h"),
            # ATen Base
            ("aten/src", "ATen/*.h"),
            ("aten/src", "ATen/cpu/**/*.h"),
            ("aten/src", "ATen/detail/*.h"),
            ("aten/src", "ATen/quantized/*.h"),
            ("aten/src", "ATen/vulkan/*.h"),
            ("aten/src", "ATen/metal/*.h"),
            ("aten/src", "ATen/nnapi/*.h"),
            # ATen Native
            ("aten/src", "ATen/native/*.h"),
            ("aten/src", "ATen/native/ao_sparse/quantized/cpu/*.h"),
            ("aten/src", "ATen/native/cpu/**/*.h"),
            ("aten/src", "ATen/native/sparse/*.h"),
            ("aten/src", "ATen/native/nested/*.h"),
            ("aten/src", "ATen/native/quantized/*.h"),
            ("aten/src", "ATen/native/quantized/cpu/*.h"),
            ("aten/src", "ATen/native/transformers/*.h"),
            ("aten/src", "ATen/native/ufunc/*.h"),
            ("aten/src", "ATen/native/utils/*.h"),
            ("aten/src", "ATen/native/vulkan/ops/*.h"),
            ("aten/src", "ATen/native/xnnpack/*.h"),
            ("aten/src", "ATen/mps/*.h"),
            ("aten/src", "ATen/native/mps/*.h"),
            # Remove the following after modifying codegen for mobile.
            ("aten/src", "ATen/mkl/*.h"),
            ("aten/src", "ATen/native/mkl/*.h"),
            ("aten/src", "ATen/native/mkldnn/*.h"),
        ]),
        visibility = ["PUBLIC"],
        feature = feature,
        labels = labels,
    )

    fb_xplat_cxx_library(
        name = "aten_vulkan_header",
        header_namespace = "",
        exported_headers = subdir_glob([
            ("aten/src", "ATen/native/vulkan/*.h"),
            ("aten/src", "ATen/native/vulkan/api/*.h"),
            ("aten/src", "ATen/native/vulkan/ops/*.h"),
            ("aten/src", "ATen/vulkan/*.h"),
        ]),
        feature = feature,
        labels = labels,
        visibility = ["PUBLIC"],
    )

    fb_xplat_cxx_library(
        name = "jit_core_headers",
        header_namespace = "",
        exported_headers = subdir_glob([("", x) for x in jit_core_headers]),
        feature = feature,
        labels = labels,
    )

    fb_xplat_cxx_library(
        name = "torch_headers",
        header_namespace = "",
        exported_headers = subdir_glob(
            [
                ("torch/csrc/api/include", "torch/**/*.h"),
                ("", "torch/csrc/**/*.h"),
                ("", "torch/csrc/generic/*.cpp"),
                ("", "torch/script.h"),
                ("", "torch/library.h"),
                ("", "torch/custom_class.h"),
                ("", "torch/custom_class_detail.h"),
                # Add again due to namespace difference from aten_header.
                ("", "aten/src/ATen/*.h"),
                ("", "aten/src/ATen/quantized/*.h"),
            ],
            exclude = [
                # Don't need on mobile.
                "torch/csrc/Exceptions.h",
                "torch/csrc/python_headers.h",
                "torch/csrc/utils/auto_gil.h",
                "torch/csrc/jit/serialization/mobile_bytecode_generated.h",
            ],
        ),
        feature = feature,
        labels = labels,
        visibility = ["PUBLIC"],
        deps = [
            ":generated-version-header",
        ],
    )

    fb_xplat_cxx_library(
        name = "aten_test_header",
        header_namespace = "",
        exported_headers = subdir_glob([
            ("aten/src", "ATen/test/*.h"),
        ]),
    )

    fb_xplat_cxx_library(
        name = "torch_mobile_headers",
        header_namespace = "",
        exported_headers = subdir_glob(
            [
                ("", "torch/csrc/jit/mobile/*.h"),
            ],
        ),
        feature = feature,
        labels = labels,
        visibility = ["PUBLIC"],
    )

    fb_xplat_cxx_library(
        name = "generated_aten_config_header",
        header_namespace = "ATen",
        exported_headers = {
            "Config.h": ":generate_aten_config[Config.h]",
        },
        feature = feature,
        labels = labels,
    )

    fb_xplat_cxx_library(
        name = "generated-autograd-headers",
        header_namespace = "torch/csrc/autograd/generated",
        exported_headers = {
            "Functions.h": ":gen_aten_libtorch[autograd/generated/Functions.h]",
            "VariableType.h": ":gen_aten_libtorch[autograd/generated/VariableType.h]",
            "variable_factories.h": ":gen_aten_libtorch[autograd/generated/variable_factories.h]",
            # Don't build python bindings on mobile.
            #"python_functions.h",
        },
        feature = feature,
        labels = labels,
        visibility = ["PUBLIC"],
    )

    fb_xplat_cxx_library(
        name = "generated-version-header",
        header_namespace = "torch",
        exported_headers = {
            "version.h": ":generate-version-header[version.h]",
        },
        feature = feature,
        labels = labels,
    )

    # @lint-ignore BUCKLINT
    fb_native.genrule(
        name = "generate-version-header",
        srcs = [
            "torch/csrc/api/include/torch/version.h.in",
            "version.txt",
        ],
        cmd = "$(exe {}tools/setup_helpers:gen-version-header) ".format(ROOT_PATH) + " ".join([
            "--template-path",
            "torch/csrc/api/include/torch/version.h.in",
            "--version-path",
            "version.txt",
            "--output-path",
            "$OUT/version.h",
        ]),
        outs = {
            "version.h": ["version.h"],
        },
        default_outs = ["."],
    )

    # @lint-ignore BUCKLINT
    fb_native.filegroup(
        name = "aten_src_path",
        srcs = [
            "aten/src/ATen/native/native_functions.yaml",
            "aten/src/ATen/native/tags.yaml",
            # @lint-ignore BUCKRESTRICTEDSYNTAX
        ] + glob(["aten/src/ATen/templates/*"]),
        visibility = [
            "PUBLIC",
        ],
    )

    fb_xplat_cxx_library(
        name = "common_core",
        srcs = [
            "caffe2/core/common.cc",
        ],
        apple_sdks = (IOS, MACOSX, APPLETVOS),
        compiler_flags = get_pt_compiler_flags(),
        feature = feature,
        labels = labels,
        link_whole = True,
        visibility = ["PUBLIC"],
        windows_preferred_linkage = "static" if is_arvr_mode() else None,
        deps = [
            ":caffe2_headers",
            ROOT_PATH + "c10:c10",
        ],
    )

    fb_python_library(
        name = "substitutelib",
        srcs = ["tools/substitute.py"],
        base_module = "",
    )

    fb_python_binary(
        name = "substitute",
        main_module = "tools.substitute",
        visibility = ["PUBLIC"],
        deps = [
            ":substitutelib",
        ],
    )

    fb_native.genrule(
        name = "generate_aten_config",
        srcs = [
            "aten/src/ATen/Config.h.in",
        ],
        cmd = "$(exe :substitute) " + " ".join([
            "--install_dir",
            "$OUT",
            "--input-file",
            "aten/src/ATen/Config.h.in",
            "--output-file",
            "Config.h",
            "--replace",
            "@AT_MKLDNN_ENABLED@",
            "ATEN_MKLDNN_ENABLED_FBXPLAT",
            "--replace",
            "@AT_MKL_ENABLED@",
            "ATEN_MKL_ENABLED_FBXPLAT",
            "--replace",
            "@AT_MKL_SEQUENTIAL@",
            "ATEN_MKL_SEQUENTIAL_FBXPLAT",
            "--replace",
            "@AT_FFTW_ENABLED@",
            "0",
            "--replace",
            "@AT_POCKETFFT_ENABLED@",
            "0",
            "--replace",
            "@AT_NNPACK_ENABLED@",
            "ATEN_NNPACK_ENABLED_FBXPLAT",
            "--replace",
            "@CAFFE2_STATIC_LINK_CUDA_INT@",
            "CAFFE2_STATIC_LINK_CUDA_FBXPLAT",
            "--replace",
            "@AT_BUILD_WITH_BLAS@",
            "USE_BLAS_FBXPLAT",
            "--replace",
            "@AT_PARALLEL_OPENMP@",
            "AT_PARALLEL_OPENMP_FBXPLAT",
            "--replace",
            "@AT_PARALLEL_NATIVE@",
            "AT_PARALLEL_NATIVE_FBXPLAT",
            "--replace",
            "@AT_PARALLEL_NATIVE_TBB@",
            "AT_PARALLEL_NATIVE_TBB_FBXPLAT",
            "--replace",
            "@AT_BUILD_WITH_LAPACK@",
            "USE_LAPACK_FBXPLAT",
            "--replace",
            "@AT_BLAS_F2C@",
            "AT_BLAS_F2C_FBXPLAT",
            "--replace",
            "@AT_BLAS_USE_CBLAS_DOT@",
            "AT_BLAS_USE_CBLAS_DOT_FBXPLAT",
        ]),
        outs = {
            "Config.h": ["Config.h"],
        },
        default_outs = ["."],
    )

    fb_python_binary(
        name = "gen_aten_bin",
        main_module = "torchgen.gen",
        visibility = [
            "PUBLIC",
        ],
        deps = [
            ROOT_PATH + "torchgen:torchgen",
        ],
    )

    fb_python_binary(
        name = "gen_unboxing_bin",
        main_module = "tools.jit.gen_unboxing",
        visibility = [
            "PUBLIC",
        ],
        deps = [
            ROOT_PATH + "tools/jit:jit",
        ],
    )

    fb_python_library(
        name = "gen_oplist_lib",
        srcs = subdir_glob([
            ("tools/code_analyzer", "gen_oplist.py"),
            ("tools/code_analyzer", "gen_op_registration_allowlist.py"),
        ]),
        base_module = "",
        tests = [
            ":gen_oplist_test",
        ],
        deps = [
            get_third_party_lib("pyyaml"),
            ROOT_PATH + "tools/lite_interpreter:gen_selected_mobile_ops_header",
            ROOT_PATH + "torchgen:torchgen",
        ],
    )

    fb_python_library(
        name = "gen_operators_yaml_lib",
        srcs = subdir_glob([
            ("tools/code_analyzer", "gen_operators_yaml.py"),
            ("tools/code_analyzer", "gen_op_registration_allowlist.py"),
        ]),
        base_module = "",
        tests = [
            ":gen_operators_yaml_test",
        ],
        deps = [
            get_third_party_lib("pyyaml"),
            ROOT_PATH + "torchgen:torchgen",
        ],
    )

    fb_python_binary(
        name = "gen_aten_vulkan_spv_bin",
        main_module = "aten.src.ATen.gen_vulkan_spv",
        visibility = [
            "PUBLIC",
        ],
        deps = [
            ":gen_aten_vulkan_spv_lib",
        ],
    )

    fb_python_library(
        name = "gen_aten_vulkan_spv_lib",
        srcs = [
            "aten/src/ATen/gen_vulkan_spv.py",
        ],
        base_module = "",
        deps = [
            ROOT_PATH + "torchgen:torchgen",
        ],
    )

    fb_python_binary(
        name = "gen_oplist",
        main_module = "gen_oplist",
        visibility = ["PUBLIC"],
        deps = [
            ":gen_oplist_lib",
        ],
    )

    fb_python_binary(
        name = "gen_operators_yaml",
        main_module = "gen_operators_yaml",
        visibility = ["PUBLIC"],
        deps = [
            ":gen_operators_yaml_lib",
        ],
    )

    # Base library shared by lite-interpreter and full-jit.
    fb_xplat_cxx_library(
        name = "torch_common",
        srcs = core_sources_common,
        apple_sdks = (IOS, MACOSX),
        compiler_flags = get_pt_compiler_flags(),
        exported_preprocessor_flags = get_pt_preprocessor_flags(),
        fbandroid_compiler_flags = get_c2_fbandroid_xplat_compiler_flags(),
        fbobjc_configs = get_pt_fbobjc_configs()["fbobjc_configs"],
        fbobjc_ios_compiler_flags = get_pt_fbobjc_configs()["fbobjc_compiler_flags"],
        fbobjc_linker_flags = get_pt_fbobjc_configs()["fbobjc_linker_flags"],
        fbobjc_macosx_compiler_flags = get_pt_fbobjc_configs()["fbobjc_macosx_compiler_flags"],
        fbobjc_macosx_configs_override = get_pt_fbobjc_configs()["fbobjc_macosx_configs_override"],
        feature = Msgr_Mobile_ProductInfra,
        labels = [
            "supermodule:android/default/pytorch",
            "supermodule:ios/default/public.pytorch",
        ],
        link_whole = True,
        visibility = ["PUBLIC"],
        deps = [
            ":aten_cpu",
            ":generated-autograd-headers",
            ":torch_headers",
            "//xplat/caffe2/c10:c10",
        ],
    )

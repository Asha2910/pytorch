# Only used for PyTorch open source BUCK build
# @lint-ignore-every BUCKRESTRICTEDSYNTAX
load(":buck_helpers.bzl", "filter_attributes", "to_oss_deps")

def fb_python_library(**kwgs):
    if read_config("pt", "is_oss", "0") == "0":
        fail("This file is for open source pytorch build. Do not use it in fbsource!")

    python_library(**kwgs)

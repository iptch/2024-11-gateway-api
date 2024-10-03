#!/usr/bin/env python

import time


def sample_function(name: str, arg: int):
    if arg > 0:
        # comment
        return 42
    return f"this is a {name}"


def main():
    time.sleep(10)
    return sample_function("jakob", 10)

#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import setup

def gen_data_files(package_dir, subdir):
    import os.path
    results = []
    for root, dirs, files in os.walk(os.path.join(package_dir, subdir)):
        results.extend([os.path.join(root, f)[len(package_dir)+1:] for f in files])
    return results

ino_package_data = gen_data_files('ino', 'make') + gen_data_files('ino', 'packages')

setup(
    name='ino-cocoduino',
    version='0.3.2',
    description='Modified version of ino for Cocoduino.',
    author='Amperka, Fabian Kreiser',
    license='MIT',
    keywords="arduino build system",
    url='http://inotool.org',
    packages=['ino', 'ino.commands'],
    package_data={'ino': ino_package_data},
)
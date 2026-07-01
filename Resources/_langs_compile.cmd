@echo off

pushd %CD%
cd /d %~dp0

python ./_langs_compile.py

popd

pause

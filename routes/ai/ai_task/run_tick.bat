@echo off
cd /d "%~dp0"
node dist/index.js %* >> state\cron_tick.log 2>&1
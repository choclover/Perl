
@ECHO OFF

if "%1" == "-svn" goto SVN
if "%1" == "-cvs" goto CVS

set IP_NUM=200

rem goto END

rem set REPOS_HOME=D:\Coding\Repository
set REPOS_HOME=c:\Coding\Repository

:SVN
rem cd %REPOS_HOME%
rem D:

rem svnserve -d -r %REPOS_HOME%\svn_repos  --listen-host 127.0.0.1
rem svnserve -d -r %REPOS_HOME%\svn_repos  --listen-host %1

@echo on
svnserve -d -r %REPOS_HOME%\svn_repos --listen-host 127.0.0.1
@echo off

goto END


:CVS


:END


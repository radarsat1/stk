# PKG_GET can be used to check for the presence of a dependent library
# in the local folder.  If it is found, it is used.  Otherwise we try
# to find it using pkg-config, or download and build it using git or
# from a tarball.
#
# Note that VARIABLE-PREFIX is also the directory name that will be
# used to hold the code for the dependency.

# PKG_GET_INIT
# ------------
AC_DEFUN([PKG_GET_INIT], [
AC_ARG_VAR([GIT], [path to git utility])
AC_ARG_VAR([CURL], [path to curl utility])

PKG_GET_tool=git
if test "x$ac_cv_env_GIT_set" != "xset"; then
  AC_PATH_TOOL([GIT], [git])
fi
if test "x$GIT" = x; then
  PKG_GET_tool=curl
  if test "x$ac_cv_env_CURL_set" != "xset"; then
	  AC_PATH_TOOL([CURL], [curl])
  fi
  if test "x$CURL" = x; then
    PKG_GET_tool=none
  fi
fi
])# PKG_GET_INIT

# PKG_GET(VARIABLE-PREFIX, PKG_CONFIG_NAME,
# GIT_URL, GIT_TAG, TAR_URL, DIR_INCLUDE, DIR_LIB,
# [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
#
#
# Note that if there is a possibility the first call to
# PKG_GET might not happen, you should be sure to include an
# explicit call to PKG_GET_INIT in your configure.ac
#
#
# --------------------------------------------------------------
AC_DEFUN([PKG_GET],
[AC_REQUIRE([PKG_GET_INIT])dnl
AC_ARG_VAR([$1][_CFLAGS], [C compiler flags for $1, overriding pkg-config])dnl
AC_ARG_VAR([$1][_LIBS], [linker flags for $1, overriding pkg-config])dnl

# Order of checks:
# If a local dir exists, use it
# Otherwise, try pkg-config
# Otherwise, try to download using git
# Otherwise, try to download using curl
# If downloaded, rename the directory to the module name, configure & make
# Note, ACTION-IF-FOUND is not executed if pkg-config is used successfully.

if test -d $1; then
  $8
else
  PKG_CHECK_MODULES([$1],[$2], , [
    AC_MSG_CHECKING([if we can download $1])
    DL_SUCCESS=true
    CD_GOBACK=$PWD
    if test "x$PKG_GET_tool" = xnone; then
      AC_MSG_RESULT([no])
      $9
    elif test "x$3" != x && test "x$PKG_GET_tool" = xgit; then
      AC_MSG_RESULT([git])
      echo $GIT clone $3 $1
      if $GIT clone $3 $1 && test "x$4" != x; then
        cd $1
        echo git checkout $4
        if ! git checkout $4; then
          DL_SUCCESS=false
        fi
        cd $CD_GOBACK
      else
        DL_SUCCESS=false
      fi
    elif test "x$5" != x && test "x$PKG_GET_tool" = xcurl; then
      AC_MSG_RESULT([curl])
      echo $CURL -L $5
      DL_dir="`$CURL -L $5 | tar -xzv | cut -d/ -f1 | sort -u | head -n1`"
      if test -d "$DL_dir"; then
        mv -v "$DL_dir" "$1"
      else
        DL_SUCCESS=false
      fi
    fi
    if $DL_SUCCESS && test -d $1; then
      if cd $1 \
        && ./configure $ARGS \
        && make
      then
        cd $CD_GOBACK
        $8
      else
        cd $CD_GOBACK
        $9
      fi
    else
      $9
    fi
  ])
fi

])# PKG_GET

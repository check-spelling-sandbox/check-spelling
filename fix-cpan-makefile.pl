#!/usr/bin/env -S perl -pi.0
s<CONFIGDEP =.*><CONFIGDEP =>;
s<XSUBPPDEPS =.*><XSUBPPDEPS =>;
s<: \Q$(PERL_HDRS)\E><:>;
s<ABSPERL =.*><ABSPERL = /usr/bin/perl>;
s<NOECHO =.*><NOECHO =>;
s<MKPATH =.*><MKPATH = mkdir -p -->;
if (m<pm_to_blib\(>) {
    s{'\\''(.*?)'\\''}{q<$1>}g;
    s/'/"/g;
};
if (m/MY->fixin/) { s/'/"/g; }

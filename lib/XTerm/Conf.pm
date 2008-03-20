# -*- perl -*-

#
# $Id: Conf.pm,v 1.1 2008/03/20 23:03:46 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2006,2008 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de/eserte/
#

package XTerm::Config;

# Plethora of xterm control sequences:
# http://rtfm.etla.org/xterm/ctlseq.html

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION = '0.01';

require Exporter;
@ISA = qw(Exporter);
@EXPORT    = qw(xterm_config);
@EXPORT_OK = qw(xterm_config_string);

use Getopt::Long;

use constant BEL => "";
use constant ESC => "";

use constant IND   => ESC . "D"; # Index
use constant IND_8   => chr 0x84;
use constant NEL   => ESC . "E"; # Next Line
use constant NEL_8   => chr 0x85;
use constant HTS   => ESC . "H"; # Tab Set
use constant HTS_8   => chr 0x88;
use constant RI    => ESC . "M"; # Reverse Index
use constant RI_8    => chr 0x8d;
use constant SS2   => ESC . "N"; # Single Shift Select of G2 Character Set: affects next character only
use constant SS2_8   => chr 0x8e;
use constant SS3   => ESC . "O"; # Single Shift Select of G3 Character Set: affects next character only
use constant SS3_8   => chr 0x8f;
use constant DCS   => ESC . "P"; # Device Control String
use constant DCS_8   => chr 0x90;
use constant SPA   => ESC . "V"; # Start of Guarded Area
use constant SPA_8   => chr 0x96;
use constant EPA   => ESC . "W"; # End of Guarded Area
use constant EPA_8   => chr 0x97;
use constant SOS   => ESC . "X"; # Start of String
use constant SOS_8   => chr 0x98;
use constant DECID => ESC . "Z"; # Return Terminal ID Obsolete form of CSI c (DA).
use constant DECID_8 => chr 0x9a;
use constant CSI   => ESC . "["; # Control Sequence Introducer
use constant CSI_8   => chr 0x9b;
use constant ST    => ESC . "\\"; # String Terminator
use constant ST_8    => chr 0x9c;
use constant OSC   => ESC . "]";
use constant OSC_8   => chr 0x9d;
use constant PM    => ESC . "^"; # Privacy Message
use constant PM_8    => chr 0x9e;
use constant APC   => ESC . "_"; # Application Program Command
use constant APC_8   => chr 0x9f;

my %o;
my $need_reset_terminal;

sub xterm_config_string {
    local @ARGV = @_;

    %o = ();
    $need_reset_terminal++;

    GetOptions(\%o,
	       "iconname=s",
	       "title=s",
	       "fg|foreground=s",
	       "bg|background=s",
	       "textcursor=s",
	       "mousefg|mouseforeground=s",
	       "mousebg|mousebackground=s",
	       "tekfg|tekforeground=s",
	       "tekbg|tekbackground=s",
	       "highlightcolor=s",
	       "bell",
	       "cs=s",
	       "fullreset",
	       "softreset",
	       "smoothscroll!", # no visual effect
	       "reverse|reversevideo!",
	       "origin!",
	       "wraparound!",
	       "autorepeat!",
	       "formfeed!",
	       "showcursor!",
	       "showscrollbar!", # rxvt
	       "tektronix!",
	       "marginbell!",
	       "reversewraparound!",
	       "backsendsdelete!",
	       "bottomscrolltty!", # rxvt
	       "bottomscrollkey!", # rxvt
	       "metasendsesc|metasendsescape!",
	       "scrollregion=s",
	       "deiconify",
	       "iconify",
	       "geometry=s",
	       "raise",
	       "lower",
	       "refresh|x11refresh",
	       "maximize",
	       "unmaximize",
	       "xproperty|x11property=s",
	       "font=s",
	       "nextfont",
	       "prevfont",
	       "report=s",
	       "debugreport",
	       "resize=i",
	      )
	or die "usage?";
    die "usage?" if (@ARGV);

    my $rv = "";

    $rv .= BEL if $o{bell};

 CS_SWITCH: {
	if (defined $o{cs}) {
	    $rv .= (ESC . '%G'), last if $o{cs} =~ m{^utf-?8$}i;
	    $rv .= (ESC . '%@'), last if $o{cs} =~ m{^(latin-?1|iso-?8859-?1)$}i;
	    warn "Unhandled -cs parameter $o{cs}\n";
	}
    }

    $rv .= ESC . "c" if $o{fullreset};

    {
	my %DECSET = qw(smoothscroll 4
			reverse 5
			origin 6
			wraparound 7
			autorepeat 8
			formfeed 18
			showcursor 25
			showscrollbar 30
			tektronix 38
			marginbell 44
			reversewraparound 45
			backsendsdelete 67
			bottomscrolltty 1010
			bottomscrollkey 1011
			metasendsesc 1036
		      );
	while(my($optname, $Pm) = each %DECSET) {
	    if (defined $o{$optname}) {
		my $onoff = $o{$optname} ? 'h' : 'l';
		$rv .= CSI . '?' . $Pm . $onoff;
	    }
	}
    }

    $rv .= CSI . '!p' if $o{softreset};

    if (defined $o{scrollregion}) {
	if ($o{scrollregion} eq '' || $o{scrollregion} eq 'default') {
	    $rv .= CSI . 'r';
	} else {
	    my($top,$bottom) = split /,/, $o{scrollregion};
	    for ($top, $bottom) {
		die "Not a number: $_\n" if !/^\d*$/;
	    }
	    $rv .=  CSI . $top . ";" . $bottom . "r";
	}
    }

    $rv .= CSI . "1t" if $o{deiconify};
    $rv .= CSI . "2t" if $o{iconify};

    if (defined $o{geometry}) {
	if (my($w,$h,$wc,$hc,$x,$y) = $o{geometry} =~ m{^(?:(\d+)x(\d+)|(\d+)cx(\d+)c)?(?:\+(\d+)\+(\d+))?$}) {
	    $rv .=  CSI."3;".$x.";".$y."t" if defined $x;
	    $rv .=  CSI."4;".$h.";".$w."t" if defined $h; # does not work?
	    $rv .=  CSI."8;".$hc.";".$wc."t" if defined $hc; # does not work?
	} else {
	    die "Cannot parse geometry string, must be width x height+x+y\n";
	}
    }

    $rv .= CSI . "5t" if $o{raise};
    $rv .= CSI . "6t" if $o{lower};
    $rv .= CSI . "7t" if $o{refresh};
    $rv .= CSI . "9;0t" if $o{unmaximize}; # does not work?
    $rv .= CSI . "9;1t" if $o{maximize}; # does not work?
    if ($o{resize}) {
	die "-resize parameter must be at least 24\n"
	    if $o{resize} < 24 || $o{resize} !~ /^\d+$/;
	$rv .= CSI . $o{resize} . 't';
    }

    $rv .= OSC .  "1;$o{iconname}" . BEL if defined $o{iconname};
    $rv .= OSC .  "2;$o{title}" . BEL if defined $o{title};
    $rv .= OSC .  "3;$o{xproperty}" . BEL if defined $o{xproperty};    
    $rv .= OSC . "10;$o{fg}" . BEL if defined $o{fg};
    $rv .= OSC . "11;$o{bg}" . BEL if defined $o{bg};
    $rv .= OSC . "12;$o{textcursor}" . BEL if defined $o{textcursor};
    $rv .= OSC . "13;$o{mousefg}" . BEL if defined $o{mousefg};
    $rv .= OSC . "14;$o{mousebg}" . BEL if defined $o{mousebg};
    $rv .= OSC . "15;$o{tekfg}" . BEL if defined $o{tekfg};
    $rv .= OSC . "16;$o{tekbg}" . BEL if defined $o{tekbg};
    $rv .= OSC . "17;$o{highlightcolor}" . BEL if defined $o{highlightcolor};
    $rv .= OSC . "50;#$o{font}" . BEL if defined $o{font};
    $rv .= OSC . "50;#-" . BEL if $o{prevfont};
    $rv .= OSC . "50;#+" . BEL if $o{nextfont};

    if ($o{report}) {
	if ($o{report} eq 'cgeometry') {
	    my($h,$w) = _report_cgeometry();
	    $rv .= $w."x".$h."\n";
	} else {
	    my $sub = "_report_" . $o{report};
	    no strict 'refs';
	    my(@args) = &$sub;
	    $rv .= join(" ", @args) . "\n";
	}
    }

    $rv;
}

sub xterm_config {
    my $rv = xterm_config_string(@_);
    print $rv;
}

sub _report ($$) {
    my($cmd, $rx) = @_;

    require Term::ReadKey;
    Term::ReadKey::ReadMode(5);

    my $debug = $o{debugreport};

    open my $TTY, "+<", "/dev/tty" or die "Cannot open terminal: $!";
    syswrite $TTY, $cmd;
    my $res = "";
    my @args;
    while() {
	sysread $TTY, my $ch, 1 or die "Cannot sysread: $!";
	print STDERR ord($ch)." " if $debug;
	$res .= $ch;
	last if (@args = $res =~ $rx);
    }

    Term::ReadKey::ReadMode(0);
    @args;
}

sub _report_status      { _report CSI.'5n', qr{0n} }
sub _report_cursorpos   { _report CSI.'6n', qr{(\d+);(\d+)R} }
sub _report_windowpos   { _report CSI.'13t', qr{;(\d+);(\d+)t} }
sub _report_geometry    { _report CSI.'14t', qr{;(\d+);(\d+)t} }
sub _report_cgeometry   { _report CSI.'18t', qr{;(\d+);(\d+)t} }
sub _report_cscreengeom { _report CSI.'19t', qr{;(\d+);(\d+)t} }
sub _report_iconlabel   { _report CSI.'20t', qr{L(.*?)(?:\Q@{[ST]}\E|\Q@{[ST_8]}\E)} }
sub _report_title       { _report CSI.'21t', qr{l(.*?)(?:\Q@{[ST]}\E|\Q@{[ST_8]}\E)} }

END {
    Term::ReadKey::ReadMode(0)
	    if $need_reset_terminal && defined &Term::ReadKey::ReadMode;
}

return 1 if caller;

xterm_config(@ARGV);

__END__

=head1 NAME

XTerm::Config - change configuration of a running xterm

=head1 SYNOPSIS

    use XTerm::Config;
    xterm_config(-fg => "white", -bg => "black", -title => "Hello, world", ...);

=head1 AUTHOR

Slaven ReziE<0x107>

=head1 SEE ALSO

L<Term::Title>, L<xterm(1)>.

=cut

#!/usr/bin/perl --
# usage:
#  dpkg-scanpackages .../binary .../noverride pathprefix >.../Packages.new
#  mv .../Packages.new .../Packages
#
# This is the core script that generates Packages files (as found
# on the Debian FTP site and CD-ROMs).
#
# The first argument should preferably be a relative filename, so that
# the Filename field has good information.
#
# Any desired string can be prepended to each Filename value by
# passing it as the third argument.
#
# The noverride file is a series of lines of the form
# <package> <priority> <section> <maintainer>
# where the <maintainer> field is optional.  Fields are separated by
# whitespace.  The <maintainer> field may be <old-maintainer> => <new-maintainer>
# (this is recommended).

$version= '1.0.12'; # This line modified by Makefile

%kmap= ('optional','suggests',
        'recommended','recommends',
        'class','priority',
        'package_revision','revision');

%pri= ('priority',300,
       'section',290,
       'maintainer',280,
       'version',270,
       'depends',250,
       'recommends',240,
       'suggests',230,
       'conflicts',220,
       'provides',210,
       'filename',200,
       'size',180,
       'md5sum',170,
       'description',160);

@ARGV==3 || die;

$binarydir= shift(@ARGV);
-d $binarydir || die $!;

$override= shift(@ARGV);
-e $override || die $!;

$pathprefix= shift(@ARGV);

open(F,"find $binarydir -name '*.deb' -print |") || die $!;
while (<F>) {
    chop($fn=$_);
    substr($fn,0,length($binarydir)) eq $binarydir || die $fn;
    open(C,"dpkg-deb -I $fn control |") || die "$fn $!";
    $t=''; while (<C>) { $t.=$_; }
    $!=0; close(C); $? && die "$fn $? $!";
    undef %tv;
    $o= $t;
    while ($t =~ s/^\n*(\S+):[ \t]*(.*(\n[ \t].*)*)\n//) {
        $k= $1; $v= $2;
        $k =~ y/A-Z/a-z/;
        if (defined($kmap{$k})) { $k= $kmap{$k}; }
        $v =~ s/\s+$//;
        $tv{$k}= $v;
#print STDERR "K>$k V>$v<\n";
    }
    $t =~ m/^\n*$/ || die "$fn $o / $t ?";
    defined($tv{'package'}) || die "$fn $o ?";
    $p= $tv{'package'}; delete $tv{'package'};
    if (defined($p1{$p})) {
        print(STDERR " ! Package $p (filename $fn) is repeat;\n".
                     "   ignored that one and using data from $pfilename{$p}) !\n")
            || die $!;
        next;
    }
    if (defined($tv{'filename'})) {
        print(STDERR " ! Package $p (filename $fn) has Filename field !\n") || die $!;
    }
    $tv{'filename'}= "$pathprefix$fn";
    open(C,"md5sum <$fn |") || die "$fn $!";
    chop($_=<C>); m/^[0-9a-f]{32}$/ || die "$fn \`$_' $!";
    $!=0; close(C); $? && die "$fn $? $!";
    $tv{'md5sum'}= $_;
    defined(@stat= stat($fn)) || die "$fn $!";
    $stat[7] || die "$fn $stat[7]";
    $tv{'size'}= $stat[7];
    if (length($tv{'revision'})) {
        $tv{'version'}.= '-'.$tv{'revision'};
        delete $tv{'revision'};
    }
    for $k (keys %tv) {
        $pv{$p,$k}= $tv{$k};
        $k1{$k}= 1;
        $p1{$p}= 1;
    }
    $_= substr($fn,length($binarydir));
    s#/[^/]+$##; s#^/*##;
    $psubdir{$p}= $_;
    $pfilename{$p}= $fn;
}
$!=0; close(F); $? && die "$? $!";

select(STDERR); $= = 1000; select(STDOUT);

format STDERR =
  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$packages
.

sub writelist {
    $title= shift(@_);
    return unless @_;
    print(STDERR " $title\n") || die $!;
    $packages= join(' ',sort @_);
    while (length($packages)) { write(STDERR) || die $!; }
    print(STDERR "\n") || die $!;
}

@samemaint=();

open(O,"<$override") || die $!;
while(<O>) {
    s/\s+$//;
    ($p,$priority,$section,$maintainer)= split(/\s+/,$_,4);
    next unless defined($p1{$p});
    if (length($maintainer)) {
        if ($maintainer =~ m/\s*=\>\s*/) {
            $oldmaint= $`; $newmaint= $'; $debmaint= $pv{$p,'maintainer'};
            if (!grep($debmaint eq $_, split(m:\s*//\s*:, $oldmaint))) {
                push(@changedmaint,
                     "  $p (package says $pv{$p,'maintainer'}, not $oldmaint)\n");
            } else {
                $pv{$p,'maintainer'}= $newmaint;
            }
        } elsif ($pv{$p,'maintainer'} eq $maintainer) {
            push(@samemaint,"  $p ($maintainer)\n");
        } else {
            print(STDERR " * Unconditional maintainer override for $p *\n") || die $!;
            $pv{$p,'maintainer'}= $maintainer;
        }
    }
    $pv{$p,'priority'}= $priority;
    $pv{$p,'section'}= $section;
    if (length($psubdir{$p}) && $section ne $psubdir{$p}) {
        print(STDERR " !! Package $p has \`Section: $section',".
                     " but file is in \`$psubdir{$p}' !!\n") || die $!;
        $ouches++;
    }
    $o1{$p}= 1;
}
close(O);

if ($ouches) { print(STDERR "\n") || die $!; }

$k1{'maintainer'}= 1;
$k1{'priority'}= 1;
$k1{'section'}= 1;

@missingover=();

for $p (sort keys %p1) {
    if (!defined($o1{$p})) {
        push(@missingover,$p);
    }
    $r= "Package: $p\n";
    for $k (sort { $pri{$b} <=> $pri{$a} } keys %k1) {
        next unless length($pv{$p,$k});
        $r.= "$k: $pv{$p,$k}\n";
    }
    $r.= "\n";
    $written++;
    print(STDOUT $r) || die $!;
}
close(STDOUT) || die $!;

&writelist("** Packages in archive but missing from override file: **",
           @missingover);
if (@changedmaint) {
    print(STDERR
          " ++ Packages in override file with incorrect old maintainer value: ++\n",
          @changedmaint,
          "\n") || die $!;
}
if (@samemaint) {
    print(STDERR
          " -- Packages specifying same maintainer as override file: --\n",
          @samemaint,
          "\n") || die $!;
}

print(STDERR " Wrote $written entries to output Packages file.\n") || die $!;

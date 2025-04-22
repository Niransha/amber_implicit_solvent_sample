#!/usr/bin/perl -w
#
# Create the correct prmtop file which has the proper radius and screen info for implicit solvent MD simulations.
# Created on 5/11/2020 by Ilyas Yildirim (FAU)
#
$f2o = "prmtop";
$f2w = "prmtop.new";
#
$count = -1; # This is a variable to define the parts we are storing.
$flag  = 0;
#
# How many atoms do we have in this system?
#
$size_system = `cat $f2o | grep -A 2 \"\%FLAG POINTERS\" | tail -1 | awk '{print \$1}'`;
chomp($size_system);
#
open(F2O, "<", "$f2o") || die "cannot open $f2o: $!";
while(<F2O>){
#  chomp($_);
  if((/\%FLAG ATOM_NAME/) || (/\%FLAG AMBER_ATOM_TYPE/) || (/\%FLAG RADII/) || (/\%FLAG SCREEN/)){
    $flag = 1;
    $count++; 
    $count_data = -1;
  } elsif (/\%FLAG/){
    $flag = 0;
  } elsif ((/\%FORMAT/) && ($flag == 1)){
    if(/20a4/){
      $format = 4;
    }elsif(/5E16\.8/){
      $format=16;
    }
    next;
  } else {
    if(($flag == 1) && !(/\%FORMAT/)){
      @tmp = split(//, $_);
      $tmp_data = "";
      for($i = 0; $i <= $#tmp; $i++){
        if($i % $format == $format - 1){
          $count_data++;		# This basically is the atom size, but we store data; therefore, I call it count_data.
          $tmp_data = $tmp_data.$tmp[$i];
          $tmp_data =~ s/\s+$//g;
          $tmp_data =~ s/^\s+//g;	# Empty space in front will be removed.
          $data[$count][$count_data] = $tmp_data;
          $tmp_data = "";
        } else {
          $tmp_data = $tmp_data.$tmp[$i];
        }
      }
    }
  }
}
close(F2O) || die "cannot close $f2o: $!";
#
# Create the correct arrays. Our new atom types are not recognized by LEAP. Thus, the radia and screen values of O3' and C4' atoms are corrected.
#
#for($i=0; $i <= $size_system - 1; $i++){
#  print "$data[0][$i].$data[1][$i].$data[2][$i].$data[3][$i]\n";
#};

#die;

for($i=0; $i <= $size_system - 1; $i++){
  if($data[0][$i] eq "O3'") {
    $data[2][$i] = "1.50000000E+00";
    $data[3][$i] = "8.50000000E-01";
  } elsif($data[0][$i] eq "C4'") {
    $data[2][$i] = "1.70000000E+00";
    $data[3][$i] = "7.20000000E-01";
  }
}
#
# Now, create the correct prmtop file. 
#
$count = -1;
open(F2W, ">", "$f2w") || die "cannot open $f2w: $!";
open(F2O, "<", "$f2o") || die "cannot open $f2o: $!";
while(<F2O>){
  if((/\%FLAG ATOM_NAME/) || (/\%FLAG AMBER_ATOM_TYPE/) || (/\%FLAG RADII/) || (/\%FLAG SCREEN/)){
    print F2W $_;
    $flag = 1;
    $count++; 
  } elsif (/\%FLAG/){
    $flag = 0;
  } elsif ((/\%FORMAT/) && ($flag == 1)){
    if(/20a4/){
      $dataperline = 20;
      $format = 4;
    }elsif(/5E16\.8/){
      $dataperline = 5;
      $format=16;
    }
    print F2W $_;
    $line = "";
    $count_data = 0; 
    for($i=0; $i <= $size_system -1; $i++){
      $count_data++;
      if($format == 4){
        $line = $line.sprintf("%-".$format."s", $data[$count][$i]);
      } else {
        $line = $line.sprintf("%".$format."s", $data[$count][$i]);
      }
      if($count_data % $dataperline == 0){
        $line = $line."\n";
      }
    }
    chomp($line);
    print F2W $line."\n";
  }
  if($flag == 0){
    print F2W $_;
  }
}
close(F2O) || die "cannot close $f2o: $!";
close(F2W) || die "cannot close $f2w: $!";

# This script will rewrite current Merge docs
# by making three types of changes. Pages listed in
# delete folder will be deleted entirely.
# Pages listed in add folder will be added. Pages
# listed in modify folder will be modifed as specified.
# Modifications are specified as keyword #file followed by
# path to file on the next line, then keyword #old followed by
# old text on the next line. Then keyword #new followed by new text.
# Old text must match perfectly, but you can also specify
# regex for old text.
# You can also simulate replacement just to see what text matches
# with -s flag


our @files = ();

sub readdirectory
{
    my $dir = shift;
    opendir(my $dh, $dir);
    my @entries = readdir($dh);
    for $e (@entries)
    {
	if ($e =~ /^\./)
	{
	    next;
	}
	if (-d  "$dir/$e")
	{
	    readdirectory("$dir/$e");
	}
	else
	{
	    push(@files, "$dir/$e");
	}
    }
    
}

$usage="$0 old-docs new-docs change-folders [-s]\n";

if ($#ARGV < 2)
{
    print $usage;
    exit 0;
}
$oldpath = $ARGV[0];
$newpath = $ARGV[1];
$changepath = $ARGV[2];
$sim = 0;
if ($#ARGV > 2)
{
    if ($ARGV[3] == "-s")
    {
	$sim = 1;
    }
}
# Git will have already copied items
system("cp -r $oldpath/* $newpath/");

# Remember changes that need to happen
# For each folder in old docs
# see if it should be deleted/added/modified

# First deal with additions
my $cd = $changepath . "add";
readdirectory($cd);
for $f (sort @files)
{
    print "File $f\n";
    $changepath = $f;
    $newpath = $ARGV[1];
    my @items = split /\//, $f;
    shift(@items);
    shift(@items);
    $filename = pop(@items);
    for $i (@items)
    {
	if (!-d "$newpath/$i")
	{
	    system("mkdir $newpath/$i");
	}
	$newpath = $newpath . "/" . $i;
    }
    print "cp $changepath $newpath\n";
    system("cp $changepath $newpath");
}
# Now deal with deletions
@files = ();
$changepath = $ARGV[2];
$cd = $changepath . "delete";
readdirectory($cd);
for $f (sort @files)
{
    $changepath = $f;
    $newpath = $ARGV[1];
    my @items = split /\//, $f;
    $filename = pop(@items);
    shift(@items);
    shift(@items);
    for $i (@items)
    {
	if (!-d "$newpath/$i")
	{
	    print "Path $newpath/$i does not exist\n"; 
	    last;
	}
	$newpath = $newpath . "/" . $i;
    }
    print "rm $newpath/$filename\n";
    system("rm $newpath/$filename");
}

# Now deal with modifications
# These have different syntax for specification
@files=();
%counter=();
%oldtext=();
%newtext=();
$changepath = $ARGV[2];
# There could be multiple files with mods but
# each file can specify modifications in multiple
# other files
$cd = $ARGV[1];
readdirectory($cd);
for $f (@files)
{
    push(@oldfiles, $f);
}
@files = ();
$cd = $changepath . "modify";
readdirectory($cd);
for $f (sort @files)
{
    if ($f =~ /^\s*$/)
    {
	next;
    }
    if ($f =~ /~$/)
    {
	next;
    }
    print "File to change *$f*\n";
    my $fh = new IO::File($f);
    my $mode = 0;
    my $text = "";
    my $loc = "";
    while(<$fh>)
    {
	if ($_ =~ /^\#file/)
	{
	    if ($text ne "")
	    {
		$text =~ s/\n$//;
		$newtext{$loc}{$counter{$loc}} = $text;
		$text = "";
	    }
	    $mode = 1;
	}
	elsif($_ =~ /^\#old/)
	{
	    $mode = 2;
	    $text = "";
	}
	elsif($_ =~ /^\#new/)
	{
	    $text =~ s/\n$//;
	    $oldtext{$loc}{$counter{$loc}} = $text;
	    $mode = 3;
	    $text = "";
	}
	elsif($mode == 1)
	{
	    if ($_ !~ /^\s+$/)
	    {
		$_ =~ s/\n//;
		$_ =~ s/\s+//;
		$loc = $_;
		# Needed to support multiple mods per file
		if (!exists($counter{$loc}))
		{
		    $counter{$loc} = 0;
		}
		else
		{
		    $counter{$loc}++;
		}
	    }
	}
	elsif($mode == 2 || $mode == 3)
	{
	    $text = $text . $_;
	}
    }
    if ($text ne "")
    {
	$text =~ s/\n$//;
	$newtext{$loc}{$counter{$loc}}  = $text;
    }
    for $l (keys %oldtext)
    {
	for $c (sort {$a <=> $b} keys %{$oldtext{$l}})
	{
	    print "Loc *$l* old $oldtext{$l}{$c} new $newtext{$l}{$c}\n";
	    # Check if we have a file that matches what we're looking for
	    for $f (@oldfiles)
	    {
		$filename = $f;
		if ($filename =~ /$l/)
		{
		    print "Working with $filename\n";
		    my $fh = new IO::File($filename);
		    # Read contents into a string
		    $text = "";
		    $oldt = $oldtext{$l}{$c};
		    $newt = $newtext{$l}{$c};
		    while(<$fh>)
		    {
			$text .= $_;
			
			if ($sim)
			{
			    if ($_ =~ $oldt)
			    {
				$modt = $_;
				$modt =~ s/$oldt/$newt/g;
				print "$_ matches in $filename and would be replaced as $modt\n";
			    }
			}
		    }
		    $text =~ s/$oldt/$newt/g;
		    if (!$sim)
		    {
			open(FH, '>', $filename) or die $!;
			print FH $text;
			close(FH);
		    }
		}
	    }
	}
    }
}


# Use instructions

This script will rewrite current Merge docs
by making three types of changes. Pages listed in
delete folder will be deleted entirely.
Pages listed in add folder will be added. Pages
listed in modify folder will be modifed as specified.
Modifications are specified as keyword #file followed by
path to file on the next line, then keyword #old followed by
old text on the next line. Then keyword #new followed by new text.
Old text must match perfectly, but you can also specify
regex for old text.
You can also simulate replacement just to see what text matches
with -s flag

Try it by cloning the old site twice, into an old folder and a new folder.
Then do:
```
rm -rf new/website/content
perl customize.pl old/website new/website changes
```

After this you can go to new/website and run hugo to observe new content

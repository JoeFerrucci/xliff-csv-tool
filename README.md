# xliff2csv

Need to install libxml2 and libxslt.

Very useful for exporting XLIFF from Xcode and turning them into CSV files to pass to some translator, then turn back into XLIFF and import into Xcode Project.

```ruby
# Convert a folder of .xliff files to a .csv 
# with the following name: translation_#{last_subfolder of sourcefolder}.csv
$ ruby xliff2csv.rb -S <YourSourceFolder>
```

```ruby
# Convert back the .csv file into the folder <YourTargetFolder>
$ ruby csv2xliff.rb translated_xliff.csv -T <YourTargetFolder>
```
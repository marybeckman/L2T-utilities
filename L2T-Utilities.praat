

################################################################################
# Praat object names                                                           #
################################################################################

# Regularize the name of a Sound object.
procedure sound_object: .name$
  if ! startsWith(.name$, "Sound")
    .name$ = "Sound '.name$'"
  endif
endproc


# Regularize the name of a Table object.
procedure table_object: .name$
  if ! startsWith(.name$, "Table")
    .name$ = "Table '.name$'"
  endif
endproc


# Regularize the name of a TextGrid object.
procedure textgrid_object: .name$
  if ! startsWith(.name$, "TextGrid")
    .name$ = "TextGrid '.name$'"
  endif
endproc





################################################################################
# TextGrid-specific procedures                                                 #
################################################################################

# Annotate a Sound object to TextGrid.
procedure annotate_to_textgrid: .sound_obj$
                            ... .all_tiers$
                            ... .point_tiers$
                            ... .textgrid_obj$
  select '.sound_obj$'
  To TextGrid... "'.all_tiers$'" '.point_tiers$'
  Rename... '.textgrid_obj$'
endproc


# Extract an interval from a TextGrid object.
procedure extract_interval: .textgrid$
                        ... .xmin
                        ... .xmax
  # Regularize the TextGrid object's name.
  @textgrid_object: .textgrid$
  .textgrid$ = textgrid_object.name$
  # Extract the interval.
  # Note the argument 1 denotes that times should be preserved in the
  # extracted TextGrid.
  select '.textgrid$'
  Extract part... '.xmin' '.xmax' 1
  .praat_obj$ = selected$()
endproc


# Get the xmin, xmid, and xmax of an interval on a TextGrid, given a text
# label that uniquely identifies the interval (e.g., the TrialNumber in a L2T
# Segmentation TextGrid).
procedure interval: .textgrid$
                ... .tier
                ... .label$
  # Transform the TextGrid to a Table object.
  @textgrid2table: .textgrid$
  # Search the newly created Table object for the row that corresponds to the
  # [.interval_label$].
  select 'textgrid2table.praat_obj$'
  .row_on_table = Search column... text '.label$'
  # Call @boundary_times to determine the xmin, xmid, and xmax times.
  @boundary_times: textgrid2table.praat_obj$,
               ... .row_on_table,
               ... .textgrid$,
               ... .tier
  # Import the [.xmin], [.xmid], and [.xmax] times from the @boundary_times
  # namespace.
  .xmin = boundary_times.xmin
  .xmid = boundary_times.xmid
  .xmax = boundary_times.xmax
  # Remove the Table object.
  @remove: textgrid2table.praat_obj$
endproc


procedure interval_at_time: .textgrid$, .tier, .time
  select '.textgrid$'
  .interval = Get interval at time... '.tier' '.time'
endproc


procedure interval_label_at_time: .textgrid$, .tier, .time
  select '.textgrid$'
  .interval = Get interval at time... '.tier' '.time'
  .label$ = Get label of interval... '.tier' '.interval'
endproc


procedure label_interval: .textgrid$, .tier, .interval, .label$
  select '.textgrid$'
  Set interval text... '.tier' '.interval' '.label$'
endproc


procedure insert_point: .textgrid$, .tier, .time, .label$
  select '.textgrid$'
  Insert point... '.tier' '.time' '.label$'
endproc




################################################################################
# Table-specific procedures                                                    #
################################################################################

# Determine the boundary times of some interval on a Table-like representation
# (of a portion) of a TextGrid.
procedure boundary_times: .table$
                      ... .row_on_table
                      ... .textgrid$
                      ... .tier_on_textgrid
  # Regularize the name of the [.table$] object.
  @table_object: .table$
  .table$ = table_object.name$
  # Regularize the name of the [.textgrid$] object.
  @textgrid_object: .textgrid$
  .textgrid$ = textgrid_object.name$
  # Get the approximate xmin, xmid, and xmax times from the [.table$].
  select '.table$'
  .xmin = Get value... '.row_on_table' tmin
  .xmax = Get value... '.row_on_table' tmax
  .xmid = (.xmin + .xmax) / 2
  # Get the fully precise xmin, xmid, and xmax times from the [.textgrid$].
  select '.textgrid$'
  .interval = Get interval at time... '.tier_on_textgrid' '.xmid'
  .xmin = Get start point... '.tier_on_textgrid' '.interval'
  .xmax = Get end point... '.tier_on_textgrid' '.interval'
  .xmid = (.xmin + .xmax) / 2
endproc


# Transform a TextGrid down to a Table.
procedure textgrid2table: .textgrid$
  # Regularize the TextGrid object's name.
  @textgrid_object: .textgrid$
  .textgrid$ = textgrid_object.name$
  # Transform the Segmentation TextGrid down to a Table.
  select '.textgrid$'
  # Down to Table parameters:
  #  0: Exclude the line number
  #  6: Decimal points in time values
  #  1: Include tier names
  #  0: Exclude empty intervals
  Down to Table... 0 6 1 0
  .praat_obj$ = selected$()
endproc





################################################################################
# Strings-specific procedures                                                  #
################################################################################

# Determine a filename from a Strings object of filenames.
procedure filename_from_strings: .strings_obj$
                             ... .file_type$
  select '.strings_obj$'
  n_strings = Get number of strings
  if (n_strings == 0)
    .filename$ = ""
  elif (n_strings == 1)
    .filename$ = Get string: 1
  elif (n_strings > 1)
    beginPause ("A bit of patience please...")
      comment    ("Which '.file_type$' would you like to use?")
      optionMenu ("File", 1)
      for n_string to n_strings
        .option$ = Get string... n_string
        option (.option$)
      endfor
    endPause("  ", "Select file", 2, 1)
    .filename$ = file$
  endif
  @remove: .strings_obj$
endproc


# Determine a filename from a regex-like pattern.
procedure filename_from_pattern: .pattern$
                             ... .file_type$
  # Create a Strings object, using the [.pattern$] to generate a list of 
  # candidate filenames.
  Create Strings as file list: "filenames", .pattern$
  .strings_obj$ = selected$()
  # Choose the filename from the [Strings filenames] object.
  @filename_from_strings: .strings_obj$, .file_type$
  # Import the [.filename$] from the [filename_from_strings] namespace.
  .filename$ = filename_from_strings.filename$
endproc


# Parse a filepath into its directory, basename, and extension.
procedure parse_filepath: .filepath$
  .extension$ = right$(.filepath$, 
                 ... length(.filepath$) - rindex(.filepath$, ".") + 1)
  .basename$  = right$(.filepath$ - .extension$, 
                 ... length(.filepath$ - .extension$) - rindex(.filepath$, "/"))
  .filename$  = .basename$ + .extension$
  .directory$ = left$(.filepath$, rindex(.filepath$, "/"))
endproc


# Parse a L2T-style participant ID from the basename of a file, given that
# participant's number.
procedure parse_id: .basename$ .participant_number$
  .left_ind = index(.basename$, .participant_number$)
  .last_sep = rindex(.basename$, "_")
  while (.last_sep > .left_ind)
    .basename$ = left$(.basename$, .last_sep - 1)
    .last_sep = rindex(.basename$, "_")
  endwhile
  .id$ = right$(.basename$, length(.basename$) - .left_ind + 1)
endproc


# Generate a string denoting the current time.
procedure timestamp
  .time$ = replace$(date$(), " ", "_", 0)
endproc


# Parse a participant's full ID from the filepath of an obect.
procedure participant: .filepath$,
                   ... .participant_number$
  @parse_filepath: .filepath$
  .id$ = mid$(parse_filepath.filename$,
          ... index_regex(parse_filepath.filename$, .participant_number$),
          ... 9)
endproc







################################################################################
# Editor-specific procedures                                                   #
################################################################################

# Open an Editor window, given a TextGrid name and Sound name.
procedure open_editor: .textgrid$
                   ... .sound$
  # Regularize the TextGrid object's name.
  @textgrid_object: .textgrid$
  .textgrid$ = textgrid_object.name$
  # Regularize the name of the Sound object.
  @sound_object: .sound$
  .sound$ = sound_object.name$
  # Select the TextGrid and Sound objects.
  select '.textgrid$'
  plus '.sound$'
  # Open the Editor
  Edit
endproc

procedure zoom: .editor$, .xmin, .xmax
  editor '.editor$'
    Zoom: .xmin, .xmax
  endeditor
endproc





################################################################################
# Misc. procedures                                                             #
################################################################################

# Remove an object.
procedure remove: .object$
  select '.object$'
  Remove
endproc



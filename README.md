# PageShot History Recorder

Some scripts to get your history from Firefox, then scrape it with PageShot.

The end result is a directory with files for all your history entries, and
in each file there is JSON that shows some information about the history
entry, and the JSON that PageShot extracts for the item.

## Usage

To get your profile data, do:

```sh
$ ./get-places.sh PROFILE_DIR > places.json
```

To find PROFILE_DIR, on a Mac look in 
`~/Library/Application Support/Firefox/`, especially:

```sh
less ~/Library/Application\ Support/Firefox/profiles.ini
```

This lists the directory where each profile is located (in the
`.../Firefox/` directory).

Once you have `places.json`, do:

```sh
$ ./explode-places.sh places-json/ < places.json
```

This creates a directory `places-json/` and writes a JSON file for each
entry in `places.json`.  This is safe to do multiple times, it won't
overwrite extracted data, but will add new entries/files if necessary.

Now you need to use PageShot to fetch data.  Check out [PageShot from
GitHub](https://github.com/mozilla-services/pageshot)

PageShot should be running with your normal profile.  So close Firefox, and
copy your profile into the PageShot checkout, like:

```sh
$ cp -r ~/Library/Application\ Support/Firefox/some_profile Profile
```

Then run `./bin/run-addon` to start Firefox, using this profile.  Go into
**Tools | Add-ons | Extensions | PageShot Preferences** and check "start HTTP
server".  Now restart Firefox to get the server to start.

Next run:

```sh
$ ./update-pageshots.sh places-json/
```

And admire the work happen!  You can stop the script and restart it at any
time to pick up.  Use this to retry failed pages:

```sh
$ RETRY_TIMED_OUT=1 ./update-pageshots.sh places-json/
```



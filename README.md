# Tosqa Host

There are no dependencies other than node 0.10.x:

```
git clone https://github.com/nutbolt/tosqa-host.git
cd tosqa-host
npm install
node .
```
To update to the latest code from GitHub, also force a refresh as follows:

```
cd tosqa-host
git pull
rm -rf node_modules bower_components
npm install
```

Some stuff is hard-coded, see `app/main/host.coffee`.

(this code was originally derived from jcw/housemon v0.8, see its [README][HMR])

[HMR]: https://github.com/jcw/housemon/blob/master/README-0.8.md

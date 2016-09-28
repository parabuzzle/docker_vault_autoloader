# Docker Vault Autoloader
This is an example of how to use a docker entrypoint to automatically load keys from Hashicorp's Vault based on an a single environment variable.

**This is meant as an example of my way of loading up environment variables from an external source at application runtime. This example uses Vault but it could easily be adapted to work with etcd, zookeeper, etc**

## Usage

### Define your environment variables

Put all your environment config in the `app_env` file or set a different one with the `$APP_ENV_FILE` variable.

You will use `vaultenv` to get the values for the keys you want.

example `app_env` file:

```
export PG_USER=$( vaultenv postgres/user )
export PG_PASS=$( vaultenv postgres/password )
export FOO=BAR
export ANOTHER_FROM_VAULT=$( vaultenv another/from/vault )
```

### Run the container

The entrypoint will run your command wrapped in `with_app_env` which will load your `app_env` first and pass off to the `CMD` for the container.

```
docker run -e VAULT_TOKEN=123abc -e APP_ENV=production docker_vault_autoloader
```

### Assumptions

**Your Vault is namespaced as `secret/{environment}/{keypath}`**

Examples Vault paths:

```
'secret/development/postrges/password' => 'mysecurepassword'
'secret/production/application/oauth/stocktwits' => 'mystocktwitstoken'
```

**All of your environments have the same key names**

example:

```
secret/development/postrges/password
secret/staging/postrges/password
secret/production/postrges/password
secret/mobile/postrges/password
```

## Provided Tools

### vaultenv

`vaultenv` will return the value of the given key path namespaced to the `$APP_ENV`

example:

```
vaultenv postgres/password => returns the value of secret/development/postgres/password
```

### with_app_env

`with_app_env` is used by the entrypoint that sources the `$APP_ENV_FILE` and passes off to the passed in command

example:

```
with_app_env bash => loads the environment from $APP_ENV_FILE and then gives you a bash shell
```

## Container Environment Variables

|Variable|Description|Required?|
|--------|-----------|---------|
|VAULT_TOKEN|The vault token to use for Vault calls|YES!|
|VAULT_ADDR|The vault address to connect to|YES! (default: `http://vault:8200`)|
|APP_ENV|The environment name to load from vault| YES (default: `development`)|
|APP_ENV_FILE|The file that defines what keys to load from Vault| NO (default: `/tmp/app_env`)|


## How does this work?!

The `with_app_env` script is set as the container entrypoint. It sources the `$APP_ENV_FILE` and then passes off to the `CMD`. This loads the environment.

So if your `CMD` is `bash`, when you run the container.. it actually runs this:

```
with_app_env bash
```

Inside the `$APP_ENV_FILE` you can use `vaultenv` to get values for keys from vault. `vaultenv` uses the `$VAULT_ADDR` and `$VAULT_TOKEN` to get the value of the keys passed to it. `vaultenv` takes the `$APP_ENV` and uses it to construct a path based on the key passed to it. So a call like this: `vaultenv postgres/password` returns the value from vault at the location of: `secret/{$APP_ENV}/postgres/password`

## WHY?!

Well, if you run an application that needs many secrets passed to it, you will quickly get tired of defining all the environment variables at runtime from the command line (especially if you run multiple environments that have different keys each). So I thought it would be nice to just pass in the environment and let the container fetch its keys from Vault directly at run time and load its own environment. That's what I did.


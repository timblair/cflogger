# CFLogger

CFLogger is a simple logger library for ColdFusion, loosely based around a Log4J-style interface.  Allows multiple listeners for each logger, all configurable at different log levels, to send messages to multiple destinations depending on log level.

## Basic Usage

    <cfset variables.logger = createobject("component", "cflogger.core.Logger").init()>
    <cfset variables.logger.register_listener(
        createobject("component", "cflogger.listeners.FileListener").init(
            variables.logger.levels.DEBUG, "test", "/tmp"
        )
    )>
    <cfset variables.logger.debug("Test")>

## Installation

Simply place the `cflogger` directory either in your webroot or within a custom tag path, or create a mapping called `/cflogger` to the location of the directory.

## The `cflogger.core.Logger` Component

The `Logger` component is the heart of this library.

The only argument for the `init()` function of the `Logger` component is `name`; if not provided, this will default to `application.applicationname` if it exists, otherwise the name will be randomly assigned.

Useable functions for this component are:

* `register_listener` -- register a listener instance with this logger
* `unregister_listener` -- remove a listener instance from this logger
* `get_listeners` -- returns the array of listeners registered with this logger
* `has_listeners` -- does this logger have and listeners registered?
* `debug`, `info`, `warn`, `error` and `fatal` -- log a given message at this log level

You can register multiple listeners with the same `Logger` instance; they do not all have to be at the same log level, and you can register multiple instances of the same listener type.

## Log Levels

The default log levels are defined in `cflogger.core.LogLevels` and are available by name through a public variable in the instantiated `cflogger.core.Logger` object, e.g. `variables.logger.levels['DEBUG']`.  Each log level has a function provided in the `Logger` component to write a message at that log level, e.g. `variables.logger.error("...")`.

In increasing severity the defined levels are:

1. Debug
2. Info
3. Warn
4. Error
5. Fatal

Each listener registered with the logger can be configured with a different log level; this will be the minimum level a message needs to be to be logged (so a listener configured at the WARN level will also receive ERROR and FATAL messages).  Setting the log level on the listener, rather than the logger itself, allows the flexibility to do something like log at the WARN level to database, but then have FATAL messages emailed or sent by SMS.

## Available Listeners

There are four default log listeners which can be registered with a logger in any combination, at different log levels should it be required.

Registration of a listener with the logger is via the `register_listener` function as shown above.  Most of the provided listeners use the `on_register` function to do some sanity checking (such as permissions, checking database tables exist etc) and may _unregister_ themselves should a problem occur; the unregistration of any listener will be logged in any other, previously added listeners.

The listeners below are all contained within `cflogger.listeners.*`.

### `FileListener`

Simply logs messages to a file (appending the messages if the file already exists).  Initialisation arguments are:

* `level` -- the `numeric` log level
* `file` -- the `string` filename to write to (`.log` will automatically be appeneded)
* `path` -- the `string` path to the directory in which to write the log file.

If the log file cannot be written to during the `on_register` phase, the logger will be unregistered.

### `DBListener`

Logs messages to a database table.  Currently MySQL only if the `initchecks` argument is specfied.  Initialisation arguments are:

* `level` -- the `numeric` log level
* `dsn` -- the `string` datasource name to write to
* `table` -- the `string` table name to log messages to
* `cols` -- the list of columns to write to, in the following order: logger name, log level, message, time stamp (default is `logger,level,message,stamp`)
* `leveltype` -- should we store the level as a string or a numeric value? (default is `string`)
* `initchecks` -- a `boolean` specifying if initialisation checks be run, such as checking the DSN exists and can be written to (default is `FALSE`)
* `autocreate` -- a `boolean` specifying if we should try and automatically create the appropriate table if it doesn't already exist?  Also requires `initchecks` to be true (default is `FALSE`)

If `initchecks` is specified, the following checks are performed (and the listener unregistered if any fail):

1. Does the datasource exist?
2. Does the datasource have `SELECT` and `INSERT` permissions?
3. Does the table exist?

If the final table check fails, but `autocreate` is `TRUE` then an attempt to `CREATE` the table is made; if this fails, the listener is unregistered.

### `ScopeListener`

Stores log messages within a given CF built-in scope structure, such as the `session`.  Initialisation arguments are:

* `level` -- the `numeric` log level
* `scope` -- the name of the required global CF scope: one of `server`, `application`, `client`, `session` or `request`; note that this is a `string`, _not_ a reference to the actual scope
* `key` -- the structure key name under which to store log messages in the given scope
* `limit` -- a maximum number of messages to retain in the given scope (LIFO-style)

Although not necessarily as useful for standard logging, this can be really useful in situations like when you need to store temporary messages to show to the user, that may need to persist over multiple requests (for example, the user completes an action, is redirected and a success message related to the initial action is shown).

First we create an `application`-scoped logger and then add a scope-listener to that (logging to the `session` scope):

    <cfset application.messenger = createobject("component", "cflogger.core.Logger").init()>
    <cfset application.messenger.register_listener(
        createobject("component", "cflogger.listeners.ScopeListener").init(
            variables.logger.levels.INFO, "session", "messages", 10
        )
    )>

The textual representation of the scope is evaluated on every call to write to the log (rather than just on initialisation), so it's safe to store the messenger object in a persistent scope in this way; in other words, the `session` will be the _current request_ session on every call.

Once this has been set up, messages to display to the user can be added to this logger.  For example, during the validation of a form submit you might have a mandatory `name` field which wasn't filled in:

    <cfset application.messenger.error("Please enter your name")>

In your global template file, you can then have something akin to the following to output any messages for the current session:

    <cfparam name="session.messages" default="#arraynew(1)#">
    <cfloop array="#session.messages#" index="message">
        <cfoutput>#message.msg#<br></cfoutput>
    </cfloop>
    <cfset structkeydelete(session, "messages")>

The messages are stored in the appropriate scope as an array of structures with four keys:

* `app` -- the logger name
* `date` -- when the message was logged
* `level` -- the text representation of log level (e.g. `ERROR`)
* `msg` -- the actual message content

You could use the log level to differentiate between error messages and success messages (by using the `ERROR` and `INFO` types respectively) and displaying them to the user with different styling.

### `SocketListener`

Sends each message to a waiting socket on a remote machine.  Initialisation arguments are:

* `level` -- the `numeric` log level
* `host` -- the host to connect to and send messages
* `port` -- the port number to connect to and send messages
* `timeout` -- the `numeric` timeout in seconds to wait for a socket connection
* `persistent` -- a `boolean` as to whether we should use a persistent socket connection or reconnect for every messages
* `terminator` -- a `string` line terminator (defaults to `\n`)

### `TwitterListener`

Sends each message as a status update to a [Twitter](http://twitter.com/) account.  Initialisation arguments are:

* `user` -- the Twitter username to post as
* `pass` -- the password of the Twitter user to post as

## Writing Your Own Listener

None of the loggers provide exactly what you're after?  You can easily write your own to fit the job perfectly.  Maybe you'd like those important messages sent to you via email or SMS?  What about logging to IRC, or even Jabber?

To create your own logger, just create a component that extends `cflogger.core.AbstractListener` and implement the following functions:

* `init` -- should be a `public` function that calls `super.init(level)` at a minimum
* `write` -- takes two arguments: `level` and `message`

You may also create an `on_register` function which will be called when the listener is registered with a logger.  This function takes no arguments, but you can use it to do any sanity checking before starting to write logs (for example, checking that a log file can actually be written to).

All the provided loggers are built in exactly this way, so just have a dig around in them to see what you can do, exactly what the arguments are etc.

## Licensing and Attribution

CFLogger is released under the MIT license as detailed in the LICENSE file that should be distributed with this library; the source code is [freely available](http://github.com/timblair/cflogger).

CFLogger was developed by [Tim Blair](http://tim.bla.ir/) when working on [White Label Dating](http://www.whitelabeldating.com/), while employed by [Global Personals Ltd](http://www.globalpersonals.co.uk).  Global Personals Ltd have kindly agreed to the release of this software under the license terms above.

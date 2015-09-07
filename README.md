# CQRS and Event Sourcing for Meteor [![Build Status](https://travis-ci.org/meteor-space/cqrs.svg?branch=master)](https://travis-ci.org/meteor-space/cqrs)

[![Join the chat at https://gitter.im/meteor-space/cqrs](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/meteor-space/cqrs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This package provides a simple infrastructure for building your Meteor app
with the CQRS (Command Query Responsibility Separation) and Event Sourcing
principles in mind.

This simplifies building complex applications with a strong Domain (DDD)
that is easy to test and reason about.

You can read up about these software architecture topics:
* [Martin Fowler about CQRS](http://martinfowler.com/bliki/CQRS.html)
* [Microsoft about CQRS](http://msdn.microsoft.com/en-us/library/dn568103.aspx)
* [Event Sourcing](https://github.com/eventstore/eventstore/wiki/Event-Sourcing-Basics)

A very contrived and bare bones example is the [integration test](https://github.com/meteor-space/cqrs/blob/master/tests/server_module.integration.coffee) for this package.

But of course, this package mostly makes sense for more complex business domains which are hard to show in a small contrived example :wink:

To give you a basic overview:
----------------------------------------
`space-cqrs` is a very simple implementation of a (non-distributed) version of the DDD + CQRS + Event Sourcing patterns. It provides a base class for event-sourced [Aggregates] (http://martinfowler.com/bliki/DDD_Aggregate.html) and [ProcessManagers](https://msdn.microsoft.com/en-us/library/jj591569.aspx) as well as serializable [ValueObjects](http://martinfowler.com/bliki/ValueObject.html) to model your business domain. It is not a full-blown CQRS framework with a distributed messaging service bus etc. but tries to keep everything as simple as possible and only supports messaging per-process.

It also provides a (currently) extremely basic implementation of a MongoDB based [EventStore](https://msdn.microsoft.com/en-us/library/jj591559.aspx) which works a little bit different than "normal" event store implementations because MongoDB doesn't support transactions. To circumvent this downside of MongoDB `space-cqrs` uses the concept of a `commit` which bundles multiple `events` and `commands` together into one "transaction" commit. [Here is a short blog article](http://blingcode.blogspot.co.at/2010/12/cqrs-building-transactional-event-store.html) talking about the basic concept.

It heavily uses the `space-messaging` package for Meter `EJSON` and runtime-`check`ed domain events and commands that are automatically serialized into the MongoDB and restored for you. So you don't have to deal with serialization concerns anywhere but within your value objects.

## Installation
`meteor add space:cqrs`

## Documentation
Please look through the tests to get a feeling what this package can do for you.
I hope to find time to write some more documentation together soon ;-)

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style.
Add unit / integration tests for any new or changed functionality.

## Run the tests
`meteor test-packages ./`

## Release History
You can find the release history in the [changelog](https://github.com/meteor-space/cqrs/blob/master/CHANGELOG.md)

## License
Licensed under the MIT license.

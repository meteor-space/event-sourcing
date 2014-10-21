# CQRS and Event Sourcing for Meteor [![Build Status](https://travis-ci.org/CodeAdventure/space-cqrs.svg?branch=master)](https://travis-ci.org/CodeAdventure/space-cqrs)

This package provides a simple infrastructure for building your Meteor app
with the CQRS (Command Query Responsibility Separation) and Event Sourcing
principles in mind.

This simplifies building complex applications with a strong Domain (DDD)
that is easy to test and reason about.

You can read up about these software architecture topics:
* [Martin Fowler about CQRS](http://martinfowler.com/bliki/CQRS.html)
* [Microsoft about CQRS](http://msdn.microsoft.com/en-us/library/dn568103.aspx)
* [Event Sourcing](https://github.com/eventstore/eventstore/wiki/Event-Sourcing-Basics)

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
* 2014.10.21 :: Version 0.1.0 First package release

## License
Copyright (c) 2014 Code Adventure
Licensed under the MIT license.
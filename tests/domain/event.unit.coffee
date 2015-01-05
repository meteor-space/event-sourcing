
Event = Space.cqrs.Event

describe "#{Event}", ->

  class TestEvent extends Event
    @type 'tests.event.TestEvent'

  beforeEach ->

    @params = {
      sourceId: 'test'
      data: {}
      version: 0
    }

  it 'saves references of required params', ->

    event = new TestEvent @params

    expect(event.sourceId).to.equal @params.sourceId
    expect(event.data).to.equal @params.data
    expect(event.version).to.equal @params.version

  it 'requires a params object', ->
    expect(-> new TestEvent()).to.throw Event.PARAMS_REQUIRED_ERROR

  it 'requires a source id', ->
    delete @params.sourceId
    expect(=> new TestEvent(@params)).to.throw Event.SOURCE_ID_REQUIRED_ERROR

  it 'sets data to empty object if none given', ->
    delete @params.data
    event = new TestEvent @params
    expect(event.data).to.eql {}

  it 'sets version to null if not provided', ->
    delete @params.version
    event = new TestEvent @params
    expect(event.version).to.equal null

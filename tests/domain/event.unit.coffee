
Event = Space.cqrs.Event

describe "#{Event}", ->

  beforeEach ->
    @params = sourceId: 'test', data: {}, version: 0
    @event = new Event @params

  it 'is serializable', -> expect(Event).to.extend Space.cqrs.Serializable

  it 'defines its EJSON type correctly', ->
    expect(@event.typeName()).to.equal 'Space.cqrs.Event'

  it 'defines its fields correctly', ->
    expect(Event.fields()).to.eql {
      sourceId: String
      data: Match.Optional(Object)
      version: Match.Optional(Match.Integer)
    }

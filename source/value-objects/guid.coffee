
class @Guid extends Space.messaging.Serializable

  @type 'Guid'
  @fields: id: String

  # ============== STATIC ============= #

  # Checks valid 128-bit UUIDs version 4
  @REGEXP = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

  # Generates 128-bit UUIDs version 4
  # http://en.wikipedia.org/wiki/Universally_unique_identifier
  @generate: ->

    time = new Date().getTime()

    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (current) ->

      random = (time + Math.random()*16) % 16 | 0
      yValue = '89ab'.charAt(Math.floor(Math.random()*3.99))
      time = Math.floor time / 16
      char = if current == 'x' then random else yValue

      return char.toString 16

  @isValid: (guid) -> if guid? then @REGEXP.test(guid.toString()) else false

  # ============== PROTOTYPE ============= #

  # Param <id> can be a string or another Guid instance
  constructor: (id) ->

    if id?
      throw new Error "Invalid guid given: #{id}" unless Guid.isValid(id)
    else
      id = Guid.generate()

    @id = id.toString() # convert to string representation
    Object.freeze this

  valueOf: -> @id
  toString: -> @id
  toJSON: -> @id
  toJSONValue: -> @id

  equals: (guid) -> (guid instanceof Guid) and guid.valueOf() == @valueOf()

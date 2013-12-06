I implemented cons cells in Postgres and then built functional
data structures on top of them, because it seemed like a bad idea.

People try to convince me that what I have done is actually useful,
but I'm pretty sure that vanilla SQL already has better versions
of all of this. I really need to write that down.

That said, this might be useful for introducing functional
programming concepts to people who are familiar with relational
databases.

Some related things

* http://www.edbt.org/Proceedings/2012-Berlin/papers/workshops/danac2012/a1-binnig.pdf
* https://www.pgcon.org/2011/schedule/events/357.en.html

Some ideas that are coming out

* Rows are like tuples.
* Tables are like types.
* SQL types might work as something like the Haskell `type` command

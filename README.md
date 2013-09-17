# Capacitor

Keeping a counter cache field of a foreign table relationship can significantly reduce the DB cost of reading those counts later.  But what if your traffic patterns have you choking on a pile of counter updates to the same row?

Instead of making ActiveRecord calls to change a counter field, write them to `Capacitor`.  They'll get summarized in a `redis` hash, with a separate process batch-retrieving and writing to `ActiveRecord`.  Being single-threaded, the writing process avoids row lock collisions, and absorbs traffic spikes by coalescing changes to the same row into one DB write.

You get the high writing capacity of `redis`, the safety of your primary DB remaining the source-of-truth for the counts, and near-realtime counter field reads that don't require `COUNT(*)` queries.

## Installation

Add this line to your application's Gemfile:

    gem 'capacitor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capacitor

Also, both the injecting and listening ends of Capacitor will instantiate a bare `Redis.new` and require the appropriate `redis` environment variables.

## Usage

Increment and decrement changes flow in one direction:

    ActiveRecord write > Capacitor Injector > redis > Capacitor Listener > DB

### ActiveRecord write

To buffer the 'users_count' field of your 'Widget' ActiveRecord model, add a method that calls `Capacitor.enqueue_count_change` with the `classname`, `object_id`, and a positive or negative increment.

    def enqueue_users_count_change(delta)
        Capacitor.enqueue_count_change 'Widget', widget_id, :users_count, delta
    end

### Capacitor Injector

Writes go to `redis`, incrementing or decrementing the `capacitor:incoming_hash[classname:object_id:fieldname]` key.  The same value is pushed onto `capacitor.incoming_signal_list` to wake up the `Capacitor Listener`.

### redis

Changes build indefinitely in `capacitor:incoming_hash`.  `Capacitor` tries to avoid losing changes one time by moving improperly-processed batches (such as a crashing server) to `capacitor:retry_hash`.  After a second failure, batches are moved to `capacitor:failure:<timestamp>` and that failure key is added to `capacitor:failed_hash_keys`.

### Capacitor Listener

In order to ensure changes get written, you'll need to keep a listener running, such as in your `Procfile`:

    capacitor: bundle exec rails runner "capacitor.run"

`Capacitor.loop_forever` blocks indefinitely on `capacitor.incoming_signal_list` waiting for counter changes.  

On waking, it sets aside the `capacitor:incoming_hash` to allow a new batch to start.  

### DB

Once a batch is set aside, `Capacitor Listener` loops over the `classname:object_id:fieldname` keys, trying to instantiate the `ActiveRecord` models and update their counts.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

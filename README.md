![Maintenance](https://img.shields.io/badge/maintenance-experimental-blue.svg)

# diesel-tracing

`diesel-tracing` provides connection structures that can be used as drop in
replacements for diesel connections with extra tracing and logging.

## Usage

### Feature flags

Just like diesel this crate relies on some feature flags to specify which
database driver to support. Just as in diesel configure this in your
`Cargo.toml`

```toml
[dependencies]
diesel-tracing = { version = "<version>", features = ["<postgres|mysql|sqlite>"] }
```

## Instrumentation Trait

`diesel` exposes and `Instrumentation` trait that has an implementation in this trait
as `TracingInstrumentation`. By default this will record events at DEBUG level as well
as any errors at ERROR level. Optionally you can also include the URL of the database
connection in these events.

```rust
#[cfg(feature = "postgres")]
{
    use diesel::Connection;
    use diesel::pg::PgConnection;
    use diesel_tracing::TracingInstrumentation;

    let url = std::env::var("POSTGRESQL_URL").expect("POSTGRESQL_URL env var not set");
    let mut conn = PgConnection::establish(&url)
        .expect("failed to establish connection");
    conn.set_instrumentation(TracingInstrumentation::new(false));
}
```

See the `diesel` documentation for the `diesel::Instrumentation` trait for more information
about this trait and its usage.

## Connection Wrappers

The connection wrappers provide an alternative way to add instrumentation to connections,
though their utility may be lesser compared to the `Instrumentation` trait approach.

### Establishing a connection

`diesel-tracing` has several instrumented connection structs that wrap the underlying
`diesel` implementations of the connection. As these structs also implement the
`diesel::Connection` trait, establishing a connection is done in the same way as
the `diesel` crate. For example, with the `postgres` feature flag:

```rust
#[cfg(feature = "postgres")]
{
    use diesel::Connection;
    use diesel_tracing::pg::InstrumentedPgConnection;

    let url = std::env::var("POSTGRESQL_URL").expect("POSTGRESQL_URL env var not set");
    let conn = InstrumentedPgConnection::establish(&url)
        .expect("failed to establish connection");
}
```

This connection can then be used with diesel dsl methods such as
`diesel::prelude::RunQueryDsl::execute` or `diesel::prelude::RunQueryDsl::get_results`.

### Combination with the `Instrumentation` trait

It is possible to use both the connection wrappers and the `Instrumentation` trait together
if desired, though this may lead to excessive duplicate events being created.

```rust
#[cfg(feature = "postgres")]
{
    use diesel::Connection;
    use diesel_tracing::pg::InstrumentedPgConnection;
    use diesel_tracing::TracingInstrumentation;

    let url = std::env::var("POSTGRESQL_URL").expect("POSTGRESQL_URL env var not set");
    let mut conn = InstrumentedPgConnection::establish(&url)
        .expect("failed to establish connection");
    conn.set_instrumentation(TracingInstrumentation::new(false));
}
```


### Code reuse

In some applications it may be desirable to be able to use both instrumented and
uninstrumented connections. For example, in the tests for a library. To achieve this
you can use the `diesel::Connection` trait.

```rust
fn use_connection(
    conn: &impl diesel::Connection<Backend = diesel::pg::Pg>,
) -> () {}
```

Will accept both `diesel::PgConnection` and the `InstrumentedPgConnection`
provided by this crate and this works similarly for other implementations
of `Connection` if you change the parametized Backend marker in the
function signature.

Unfortunately there are some methods specific to backends which are not
encapsulated by the `diesel::Connection` trait, so in those places it is
likely that you will just need to replace your connection type with the
Instrumented version.

## Connection Pooling

`diesel-tracing` supports the `r2d2` connection pool, through the `r2d2`
feature flag. See `diesel::r2d2` for details of usage.

## Notes

### Fields

Currently the few fields that are recorded are a subset of the `OpenTelemetry`
semantic conventions for [databases](https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/semantic_conventions/database.md).
This was chosen for compatibility with the `tracing-opentelemetry` crate, but
if it makes sense for other standards to be available this could be set by
feature flag later.

Database statements may optionally be recorded by enabling the
`statement-fields` feature. This uses [`diesel::debug_query`](https://docs.rs/diesel/latest/diesel/fn.debug_query.html)
to convert the query into a string. As this may expose sensitive information,
the feature is not enabled by default.

It would be quite useful to be able to parse connection strings to be able
to provide more information, but this may be difficult if it requires use of
diesel feature flags by default to access the underlying C bindings.

### Levels

All logged traces are currently set to DEBUG level, potentially this could be
changed to a different default or set to be configured by feature flags. At
them moment this crate is quite new and it's unclear what a sensible default
would be.

### Errors

Errors in Result objects returned by methods on the connection should be
automatically logged through the `err` directive in the `instrument` macro.

### Sensitive Information

As statements may contain sensitive information they are currently not recorded
explicitly, unless you opt in by enabling the `statement-fields` feature.
Finding a way to filter statements intelligently to solve this problem is a
TODO.

Similarly connection strings are not recorded in spans as they may contain
passwords

### TODO

- [ ] Record and log connection information (filtering out sensitive fields)
- [ ] Provide a way of filtering statements, maybe based on regex?


License: MIT

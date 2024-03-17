# 1brc-zig

[The One Billion Row Challenge](https://1brc.dev/) in Zig, just because...

## Initial thoughts

- MMAP for reading the file?
- SIMD? (`@Vector` IINM?)
- Read data in `c` chunks
- Process every chunk using `t` threads

## Steps

- [x] Use https://wikitable2csv.ggor.de/ to translate https://en.wikipedia.org/wiki/List_of_cities_by_average_temperature tables to CSVs.<br/>
  -> `data/wikipedia-data` folder`
- [x] Use **[duckdb](https://duckdb.org/)** to create `data/cities.csv`<br/>
  -> `scripts/generate_cities.sh`
- [ ] Generate random input file
- [ ] Process input file :-)

## Tools, Resources and References

- [List of cities by average temperature](https://en.wikipedia.org/wiki/List_of_cities_by_average_temperature)
- [Wiki table converter](https://wikitable2csv.ggor.de/)
- [DuckDB](https://duckdb.org): to process wiki data
- https://zigcc.github.io/zig-cookbook/01-02-mmap-file.html
- https://zig.guide/language-basics/vectors/
- https://www.openmymind.net/SIMD-With-Zig/
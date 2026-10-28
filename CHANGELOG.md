## [Unreleased]

## [0.9.0] - 2026-10-28

- Speed up validation and cut memory allocations, especially for large payloads and the `distinct` rule
- Match wildcard rule keys literally apart from `*`, so `items.*.name` no longer matches keys such as `itemsX0Xname`
- Fix default values not being set for array elements at index 10 and above

## [0.7.3] - 2025-09-12

- Fix hostname coercion
 
## [0.7.1] - 2025-09-07

- Add password rule

## [0.3.0] - 2023-04-05

- Add cleansing for data before validation


## [0.1.0] - 2022-09-22

- Initial release

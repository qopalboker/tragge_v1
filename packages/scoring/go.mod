module github.com/Parsaeffatravesh/tragge/packages/scoring

go 1.24.0

toolchain go1.24.7

require (
	github.com/Parsaeffatravesh/tragge/packages/money v0.0.0
	github.com/shopspring/decimal v1.4.0
)

replace github.com/Parsaeffatravesh/tragge/packages/money => ../money

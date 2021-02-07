unit-tests: dc-build unit-tests-dmd unit-tests-ldc

unit-tests-dmd:
	docker-compose run --rm dmd dub -q test
	docker-compose run --rm dmd dub build -b release

unit-tests-ldc:
	docker-compose run --rm ldc dub -q test
	docker-compose run --rm ldc dub build -b release

shell-dmd:
	docker-compose run --rm dmd bash

shell-ldc:
	docker-compose run --rm ldc bash

dc-build:
	docker-compose build

run-example-basic:
	docker-compose -f docker-compose.examples.yml run --workdir=/dlang/app/examples/basic --rm example dub


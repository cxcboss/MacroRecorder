.PHONY: build run clean all help

build:
	swift build

run:
	swift run

clean:
	swift package clean

all: build

help:
	@echo "Available targets:"
	@echo "  build  - Build the project"
	@echo "  run    - Run the application"
	@echo "  clean  - Clean build artifacts"
	@echo "  all    - Build the project (default)"
	@echo "  help   - Show this help message"

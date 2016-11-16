SHELL := /bin/bash

release:
	rm -rf dist
	mkdir dist
	mkdir dist/lib
	# build the bot's utility library and copy into dist/lib
	cd util && cargo build --release
	cp util/target/release/libalgobot_util.so dist/lib
	# copy libstd to the dist/lib directory
	cp $$(find $$(rustc --print sysroot)/lib | grep -E "libstd-.*\.so" | head -1) dist/lib

	# build all strategies and copy into dist/lib
	for dir in ./strategies/*; \
	do \
		cd $$dir && cargo rustc --release -- -C prefer-dynamic -L ../../util/target/release/deps -L ../../dist/lib && \
		cp target/release/lib$$(echo $$dir | sed "s/\.\/strategies\///").so ../../dist/lib; \
	done

	# build all modules and copy their binaries into the dist directory
	cd backtester && cargo build --release
	cp backtester/target/release/backtester dist
	cd spawner && cargo build --release
	cp spawner/target/release/spawner dist
	cd tick_parser && cargo build --release
	cp tick_parser/target/release/tick_processor dist
	cd optimizer && cargo build --release
	cp optimizer/target/release/optimizer dist
	cd mm && npm install
	cp ./mm dist -r

debug:
	rm -rf dist
	mkdir dist
	mkdir dist/lib
	# build the bot's utility library and copy into dist/lib
	cd util && cargo build
	cp util/target/debug/libalgobot_util.so dist/lib
	# copy libstd to the dist/lib directory
	cp $$(find $$(rustc --print sysroot)/lib | grep -E "libstd-.*\.so" | head -1) dist/lib

	# build all strategies and copy into dist/lib
	for dir in ./strategies/*; \
	do \
		cd $$dir && cargo rustc -- -C prefer-dynamic -L ../../util/target/debug/deps -L ../../dist/lib && \
		cp target/debug/lib$$(echo $$dir | sed "s/\.\/strategies\///").so ../../dist/lib; \
	done

	# build all modules and copy their binaries into the dist directory
	cd backtester && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp backtester/target/debug/backtester dist
	cd spawner && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp spawner/target/debug/spawner dist
	cd tick_parser && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp tick_parser/target/debug/tick_processor dist
	cd optimizer && RUSTFLAGS="-L ../util/target/debug/deps -L ../dist/lib -C prefer-dynamic" cargo build
	cp optimizer/target/debug/optimizer dist
	cd mm && npm install
	cp ./mm dist -r

strip:
	cd dist && strip backtester spawner optimizer tick_processor
	cd dist/lib && strip *

clean:
	rm optimizer/target -rf
	rm spawner/target -rf

	for dir in ./strategies/*/; \
	do \
		rm $$dir/target -rf; \
	done

	rm tick_parser/target -rf
	rm util/target -rf
	rm backtester/target -rf
	rm mm/node_modules -rf

test:
	cd optimizer && cargo test
	cd spawner && cargo test

	# Build each strategy
	for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo test; \
	done

	cd tick_parser && cargo test
	cd util && cargo test
	cd backtester && cargo test
	cd mm && npm install
	# TODO: Collect the results into a nice format

bench:
	cd tick_parser && cargo bench
	cd util && cargo bench
	cd backtester && cargo bench
	for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo bench; \
	done
	# TODO: Collect the results into a nice format

update:
	cd optimizer && cargo update
	cd spawner && cargo update

	# Build each strategy
	for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo update; \
	done

	cd tick_parser && cargo update
	cd util && cargo update
	cd backtester && cargo update
	cd mm && npm update

cdoc:
	cd optimizer && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd spawner && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports

	# Build each strategy
	for dir in ./strategies/*/; \
	do \
		cd $$dir && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports; \
	done

	cd tick_parser && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd util && cargo test
	cd backtester && cargo rustdoc --open -- --no-defaults --passes collapse-docs --passes unindent-comments --passes strip-priv-imports
	cd mm && npm install
	# TODO: Collect the results into a nice format

# kill off any straggler processes
kill:
	if [[ $$(ps -aux | grep '[t]arget/debug') ]]; then \
		kill $$(ps -aux | grep '[t]arget/debug' | awk '{print $$2}'); \
	fi
	if [[ $$(ps -aux | grep '[m]anager.js') ]]; then \
		kill $$(ps -aux | grep '[m]anager.js' | awk '{print $$2}'); \
	fi

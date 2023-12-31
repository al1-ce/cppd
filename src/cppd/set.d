/++
betterC compatible associative container that contains a sorted set of unique objects
+/
module cppd.set;

import cppd.allocator;
import cppd.classes;

/++
Unique value container.

Default sorting order is `a > b` for non `char*` and `ctrcmp(a, b) > 0` for `char*`.
Default sorting algorithm is bubble sort.

Prefer inserting values by bulk because it sorts after each `insert` call.
++/
alias set = CppSet;

/// Ditto
private struct CppSet(T, alias Compare = sortFunction, A = allocator!T) {
    private T* _data = null;
    private A _allocator = null;

    private size_t _size = 0;
    private size_t _capacity = 0;

    /// Returns pointer to data array
    @property T* data() { return _data; }

    /// Returns size of allocated storage space
    @property size_t capacity() { return _capacity; }

    /// Returns number of elements contained in set
    @property size_t size() { return _size; }

    /// Returns true if set is empty, i.e `size == 0`
    @property bool empty() { return _size == 0; }

    /// Returns last element or `T.init` if `size == 0`
    @property T back() { return _size == 0 ? T.init : _data[_size - 1]; }

    /// Returns first element or `T.init` if `size == 0`
    @property T front() { return _size == 0 ? T.init : _data[0]; }

    // @disable this();

    this(T[] vals...) {
        _allocator = _new!A();
        insert(vals);
    }

    ~this() { free(); }
    /// Assigns new data to vector
    void opAssign(size_t S)( T[S] p_data ) {
        clear();
        reserve(S);
        insert(p_data);
    }
    /// Ditto
    void opOpAssign(string op: "~")(T item) { insert(item); }
    /// Ditto
    void opOpAssign(string op: "~")(T[] arr) { insert(arr); }


    /// Inserts values into set if `!has(val)`
    void insert(T[] vals...) {
        for (size_t i = 0; i < vals.length; ++i) {
            if (!has(vals[i])) insertOne(vals[i]);
        }
        sort();
    }

    /// Ditto
    private void insertOne(T val) {
        if (_size >= _capacity) reserve(_capacity * 2 + 2);
        _data[_size] = val;
        ++_size;
    }

    /// Returns true if set contains value
    alias has = contains;

    /// Ditto
    bool contains(ref T val) {
        for (size_t i = 0; i < _size; ++i) if (_data[i] == val) return true;
        return false;
    }

    /// Bubble sort (it's stable, it's simple, if you using CppSet on large data)
    /// then you better rethink your life
    private void sort() {
        bool swapped;
        for (size_t i = 0; i <  _size - 1; ++i) {
            swapped = false;
            for (size_t j = 0; j < _size - i - 1; ++j) {
                if (Compare(_data[j], _data[j + 1])) {
                    T temp = _data[j];
                    _data[j] = data[j + 1];
                    _data[j + 1] = temp;
                    swapped = true;
                }
            }
            if (!swapped) break;
        }
    }

    /// Allocates memory for `p_size` elements if `p_size > capacity`
    /// Returns true on success
    bool reserve(size_t p_size) {
        if (p_size <= _capacity) return true;
        if (_allocator is null) _allocator = _new!A();

        void* newData;

        if (_data is null) {
            newData = _allocator.allocate(p_size * T.sizeof);
        } else {
            newData = _allocator.reallocate(_data, p_size * T.sizeof);
        }

        if (newData is null) return false;
        _data = cast(T*) newData;

        _capacity = p_size;

        return true;
    }

    /// Reallocates memory so that `capacity == size`.
    /// Does nothing if data is uninitialized
    /// Returns true if was successful
    bool shrink() {
        if (_size == _capacity) return true;
        if (_allocator is null) _allocator = _new!A();

        if (_data !is null) {
            void* newData;
            newData = _allocator.reallocate(_data, _size * T.sizeof);
            if (newData is null) return false;
            _data = cast(T*) newData;
            _capacity = _size;
        }

        return true;
    }

    /// Destroys vector data and sets size to 0
    void clear() {
        if (_allocator is null) _allocator = _new!A();
        void* newData = _allocator.allocate(_capacity * T.sizeof);
        if (newData is null) return;

        if (_data !is null) {
            freeData();
            _allocator.deallocate(_data);
        }

        _data = cast(T*) newData;
        _size = 0;
    }

    void free() {
        if (_data !is null) {
            freeData();
            _allocator.deallocate(_data);
        }
        if (_allocator !is null) _allocator._free();
        _data = null;
        _size = 0;
        _capacity = 0;
    }

    private void freeData() {
        if (_data !is null) {
            for (size_t i = 0; i < _size; ++i) destroy!false(_data[i]);
        }
    }
}

private bool sortFunction(T)(T a, T b) {
    static if (is(T == char*)) {
        import core.stdc.string: strcmp;
        return strcmp(a, b) > 0;
    } else {
        return a > b;
    }
}

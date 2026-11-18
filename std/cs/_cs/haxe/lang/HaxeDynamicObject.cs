using System;
using System.Collections.Generic;

namespace haxe.lang
{
    public class HaxeDynamicObject : global::haxe.lang.HaxeObject
    {
        private static int __hx_toString_depth = 0;

        private global::System.Collections.Generic.Dictionary<string, object> _hx_fields;

        public HaxeDynamicObject()
        {
        }

        // Factory method to create with initial field values
        // Usage: _hx_create(["field1", value1, "field2", value2, ...])
        public static global::haxe.lang.HaxeDynamicObject _hx_create(global::haxe.root.Array args)
        {
            var obj = new global::haxe.lang.HaxeDynamicObject();
            for (int i = 0; i < args.length; i += 2)
            {
                var name = (string)args.__objectArray[i];
                var value = args.__objectArray[i + 1];
                obj._hx_setField(name, value);
            }
            return obj;
        }

        public override string ToString()
        {
            if (__hx_toString_depth >= 5)
            {
                return "...";
            }
            ++__hx_toString_depth;
            var buf = "{";
            bool first = true;
            try
            {
                var keys = _hx_getFields();
                for (int i = 0; i < keys.length; i++)
                {
                    var key = (string)keys.__get(i);
                    if (first)
                        first = false;
                    else
                        buf += ", ";
                    buf += key;
                    buf += ": ";
                    // the Haxe conversion: toString() of Haxe objects (arrays, nested
                    // structures), lowercase booleans, invariant floats
                    var value = _hx_getField(key);
                    if (value is global::haxe.lang.HaxeObject ho)
                        buf += ho.toString();
                    else
                        buf += global::haxe.lang.Runtime.toStrConcat(value);
                }
            }
            catch (global::System.Exception)
            {
                --__hx_toString_depth;
                throw;
            }
            --__hx_toString_depth;
            buf += "}";
            return buf;
        }

        /// <summary>
        /// Haxe toString() method - checks for custom toString field first.
        /// This is called by Cs.toString() for string conversion.
        /// </summary>
        public override string toString()
        {
            // Check if there's a toString field that is a function
            object toStringField = _hx_getField("toString");
            if (toStringField is global::haxe.lang.Function f)
            {
                var result = f.__hx_invoke0().toDynamic();
                return global::haxe.lang.Runtime.toStr(result);
            }
            // Fallback to default ToString() which formats as {field: value, ...}
            return ToString();
        }

        // ---- Typed fields
        // A generated subclass (haxe.generated.*, one per known anonymous structure) stores
        // its fields in typed C# fields and overrides the four members below. Generated code
        // reads and writes those fields through the static accessors of the subclass, the
        // methods here are the dynamic path (Reflect, access through Dynamic). Everything
        // that does not fit a typed field goes to the dictionary, which is created on first
        // use: fields added at runtime, and values whose type is not the one of the field.

        /// <summary>
        /// One bit per typed field, set when the typed field holds no value: an optional
        /// field that was not given, a field removed with Reflect.deleteField, or a field
        /// whose current value is in the dictionary.
        /// </summary>
        public ulong _hx_absent;

        /// <summary>Names of the typed fields, in index order.</summary>
        protected virtual string[] _hx_typedNames() { return null; }

        /// <summary>Index of a typed field, -1 if the name is not one.</summary>
        protected virtual int _hx_typedIndex(string name) { return -1; }

        protected virtual object _hx_typedGet(int index) { return null; }

        /// <summary>
        /// Stores a value in a typed field. Returns false, and resets the field to its
        /// default, when the value is not of the type of the field.
        /// </summary>
        protected virtual bool _hx_typedSet(int index, object value) { return false; }

        public override bool _hx_deleteField(string name)
        {
            int index = _hx_typedIndex(name);
            if (index >= 0)
            {
                ulong bit = 1UL << index;
                if ((_hx_absent & bit) == 0)
                {
                    _hx_absent |= bit;
                    _hx_typedSet(index, null);
                    return true;
                }
            }
            return _hx_fields != null && _hx_fields.Remove(name);
        }

        public override global::haxe.root.Array _hx_getFields()
        {
            var result = new global::haxe.root.Array();
            var names = _hx_typedNames();
            if (names != null)
            {
                for (int i = 0; i < names.Length; i++)
                {
                    if ((_hx_absent & (1UL << i)) == 0) result.push(names[i]);
                }
            }
            if (_hx_fields != null)
            {
                foreach (var key in _hx_fields.Keys)
                {
                    int index = _hx_typedIndex(key);
                    if (index < 0 || (_hx_absent & (1UL << index)) != 0) result.push(key);
                }
            }
            return result;
        }

        public override object _hx_getField(string name)
        {
            int index = _hx_typedIndex(name);
            if (index >= 0 && (_hx_absent & (1UL << index)) == 0)
            {
                return _hx_typedGet(index);
            }
            if (_hx_fields == null) return null;
            object value;
            _hx_fields.TryGetValue(name, out value);
            return value;
        }

        public bool _hx_hasField(string name)
        {
            int index = _hx_typedIndex(name);
            if (index >= 0 && (_hx_absent & (1UL << index)) == 0) return true;
            return _hx_fields != null && _hx_fields.ContainsKey(name);
        }

        public override void _hx_setField(string name, object value)
        {
            int index = _hx_typedIndex(name);
            if (index >= 0)
            {
                if (_hx_typedSet(index, value))
                {
                    _hx_absent &= ~(1UL << index);
                    if (_hx_fields != null) _hx_fields.Remove(name);
                    return;
                }
                _hx_absent |= 1UL << index;
            }
            _hx_initFields();
            _hx_fields[name] = value;
        }

        private void _hx_initFields()
        {
            if (_hx_fields == null)
            {
                _hx_fields = new global::System.Collections.Generic.Dictionary<string, object>();
            }
        }

        public static new void _hx_bind() { }
    }
}

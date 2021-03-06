/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// This module provides routines for encoding a sequence of typed
// entities into a string.  The resulting strings can be
// lexicographically compared to yield the same comparison value that
// would have been generated if the encoded items had been compared
// one by one according to their type.
//
// More precisely, suppose:
//  1. string A is generated by encoding the sequence of items [A_1..A_n]
//  2. string B is generated by encoding the sequence of items [B_1..B_n]
//  3. The types match; i.e., for all i: A_i was encoded using
//     the same routine as B_i
// Then:
//    Comparing A vs. B lexicographically is the same as comparing
//    the vectors [A_1..A_n] and [B_1..B_n] lexicographically.
//
// Furthermore, if n < m, the encoding of [A_1..A_n] is a strict prefix of
// [A_1..A_m] (unless m = n+1 and A_m is the empty string encoded with
// WriteTrailingString, in which case the encodings are equal).
//
// This module is often useful when generating multi-part sstable
// keys that have to be ordered in a particular fashion.

#ifndef FIRESTORE_CORE_SRC_UTIL_ORDERED_CODE_H_
#define FIRESTORE_CORE_SRC_UTIL_ORDERED_CODE_H_

#include <string>

#include "absl/strings/string_view.h"

namespace firebase {
namespace firestore {
namespace util {

class OrderedCode {
 public:
  // -------------------------------------------------------------------
  // Encoding routines: each one of the following routines append
  // one item to "*dest".  The Write(Signed)NumIncreasing() and
  // Write(Signed)NumDecreasing() routines differ in whether the resulting
  // encoding is ordered by increasing number or decreasing number.
  // Similarly, WriteString() and WriteStringDecreasing() differ in whether
  // the resulting encoding is ordered by the original string in
  // lexicographically increasing or decreasing order.  WriteString()
  // is not called WriteStringIncreasing() for convenience and backward
  // compatibility.

  static void WriteString(std::string* dest, absl::string_view str);
  static void WriteNumIncreasing(std::string* dest, uint64_t num);
  static void WriteSignedNumIncreasing(std::string* dest, int64_t num);

  /**
   * Creates an encoding for the "infinite string", a value considered to
   * be lexicographically after any real string.  Note that in the case of
   * WriteInfinityDecreasing(), this would come before any real string as
   * the ordering puts lexicographically greater values first.
   */
  static void WriteInfinity(std::string* dest);

  /**
   * Special string append that can only be used at the tail end of
   * an encoded string -- blindly appends "str" to "*dest".
   */
  static void WriteTrailingString(std::string* dest, absl::string_view str);

  // -------------------------------------------------------------------
  // Decoding routines: these extract an item earlier encoded using
  // the corresponding WriteXXX() routines above.  The item is read
  // from "*src"; "*src" is modified to point past the decoded item;
  // and if "result" is non-NULL, "*result" is modified to contain the
  // result.  In case of string result, the decoded string is appended to
  // "*result".  Returns true if the next item was read successfully, false
  // otherwise.

  static bool ReadString(absl::string_view* src, std::string* result);
  static bool ReadNumIncreasing(absl::string_view* src, uint64_t* result);
  static bool ReadSignedNumIncreasing(absl::string_view* src, int64_t* result);

  static bool ReadInfinity(absl::string_view* src);
  static bool ReadTrailingString(absl::string_view* src, std::string* result);

  /** REQUIRES: next item was encoded by WriteInfinity() or WriteString(). */
  static bool ReadStringOrInfinity(absl::string_view* src,
                                   std::string* result,
                                   bool* inf);

  /**
   * Helper for testing: corrupt "*str" by changing the kth item separator
   * in the string.
   */
  static void TEST_Corrupt(std::string* str, int k);

  /**
   * Helper for testing.
   * SkipToNextSpecialByte is an internal routine defined in the .cc file
   * with the following semantics. Return a pointer to the first byte
   * in the range "[start..limit)" whose value is 0 or 255.  If no such
   * byte exists in the range, returns "limit".
   */
  static const char* TEST_SkipToNextSpecialByte(const char* start,
                                                const char* limit);

  // Not an instantiable class, but the class exists to make it easy to
  // use with a single using statement.
  OrderedCode() = delete;
  OrderedCode(const OrderedCode&) = delete;
  OrderedCode& operator=(const OrderedCode&) = delete;
};

}  // namespace util
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_UTIL_ORDERED_CODE_H_

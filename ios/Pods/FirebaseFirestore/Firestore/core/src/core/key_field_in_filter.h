/*
 * Copyright 2019 Google
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

#ifndef FIRESTORE_CORE_SRC_CORE_KEY_FIELD_IN_FILTER_H_
#define FIRESTORE_CORE_SRC_CORE_KEY_FIELD_IN_FILTER_H_

#include <string>

#include "Firestore/core/src/core/field_filter.h"
#include "Firestore/core/src/model/document.h"
#include "Firestore/core/src/model/model_fwd.h"

namespace firebase {
namespace firestore {
namespace core {

/**
 * A Filter that matches on an array of key fields.
 */
class KeyFieldInFilter : public FieldFilter {
 public:
  KeyFieldInFilter(model::FieldPath field, model::FieldValue value);

 private:
  class Rep;

  static bool Contains(const model::FieldValue::Array& array_value,
                       const model::Document& doc);

  static void ValidateArrayValue(const model::FieldValue& value);

  friend class KeyFieldNotInFilter;
};

}  // namespace core
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_CORE_KEY_FIELD_IN_FILTER_H_

/**
 *    Copyright 2019 MetaRing s.r.l.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package com.metaring.generator.util.java

import com.metaring.generator.model.data.Attribute
import com.metaring.generator.model.data.Data
import com.metaring.generator.model.data.Element
import com.metaring.generator.model.data.Functionality
import com.metaring.generator.model.data.Module

import static extension com.metaring.generator.model.util.Extensions.*

final class Extensions {

    static def getGeneratedPackageDeclaration(Element element) '''package «element.packageFQN»;'''

    static def getPackageFQN(Element element)
        '''«IF element.packagesChain !== null && !element.packagesChain.empty»«FOR pn : element.packagesChain»«pn»«IF element.packagesChain.last !== pn».«ENDIF»«ENDFOR»«ENDIF»«IF typeof(Module).isInstance(element)».«element.name»«ENDIF»'''

    static def getPackagePath(Element element) {
        element.packageFQN.toString().replace('.', '/') as CharSequence
    }

    static def getDotAwareName(Module module) {
        var name = module.name
        if (name.contains('.')) {
            name = name.substring(name.lastIndexOf('.') + 1)
        }
        return name
    }

    static def getNativeFullyQualifiedNameForImport(Attribute attribute) {
        return getNativeFullyQualifiedName(attribute, true)
    }

    static def getNativeFullyQualifiedName(Attribute attribute) {
        return getNativeFullyQualifiedName(attribute, false)
    }

    static def getNativeFullyQualifiedName(Data data) {
        return '''«FOR pn : data.packagesChain»«pn».«ENDFOR»«data.name.toFirstUpper»'''
    }

    private static def getNativeFullyQualifiedName(Attribute attribute, boolean forImport) {
        if (attribute === null) {
            return null
        }
        if (!attribute.native) {
            return '''«FOR pn : attribute.packagesChain»«pn».«ENDFOR»«attribute.name.toFirstUpper»«IF attribute.enumerator»Enumerator«ENDIF»«IF attribute.many»Series«ENDIF»'''
        }
        if (forImport && (attribute.singleText || attribute.singleDigit || attribute.singleRealDigit || attribute.singleTruth)) {
            return null;
        }

        if (attribute.singleText) {
            return 'java.lang.String'
        }
        if (attribute.singleDigit) {
            return 'java.lang.Long'
        }
        if (attribute.singleRealDigit) {
            return 'java.lang.Double'
        }
        if (attribute.singleTruth) {
            return 'java.lang.Boolean'
        }

        var fqn = DEFAULT_PACKAGE_NAME + ".type."

        if (!attribute.unknown) {
            if (attribute.many) {
                fqn += 'series.'
            }
            fqn += attribute.name
            if (attribute.many) {
                fqn += 'Series'
            }
        } else {
            fqn += 'DataRepresentation'
        }

        return fqn
    }

    static def getType(Attribute attribute) {
        if (attribute === null) {
            return null
        }
        if (!attribute.native) {
            return '''«attribute.name.toFirstUpper»«IF attribute.enumerator»Enumerator«ENDIF»«IF attribute.many»Series«ENDIF»'''
        }
        if (attribute.singleText) {
            return 'String'
        }
        if (attribute.singleDigit) {
            return 'Long'
        }
        if (attribute.singleRealDigit) {
            return 'Double'
        }
        if (attribute.singleTruth) {
            return 'Boolean'
        }

        var name = ''
        if (!attribute.unknown) {
            name += attribute.name
            if (attribute.many) {
                name += 'Series'
            }
        } else {
            name += 'DataRepresentation'
        }
        return name
    }

    def static getDataOrNativeTypeFromJsonCreatorMethod(Attribute attribute, String jsonVarName) {
        return "dataRepresentation" + attribute.createDataOrNativeTypeFromJsonCreatorMethod(jsonVarName)
    }

    def static getDataOrNativeTypeFromJsonCreatorMethod(Attribute attribute) {
        return attribute.createDataOrNativeTypeFromJsonCreatorMethod(null)
    }

    private def static createDataOrNativeTypeFromJsonCreatorMethod(Attribute attribute, String jsonVarName) {
        try {
            var typeName = attribute.name

            if (!attribute.native) {
                typeName = typeName.toFirstUpper
                if (attribute.enumerator) {
                    typeName += "Enumerator"
                }
            }

            if (attribute.unknown) {
                if(jsonVarName === null) {
                    return "";
                }
                typeName = ""
            }

            if (!attribute.unknown && attribute.many) {
                typeName += "Series"
            }

            var method = "."

            if (jsonVarName === null) {
                method += "as"
            } else {
                method += "get"
            }

            if (attribute.native) {
                method += typeName
            }

            method += "("

            if (jsonVarName !== null) {
                method += "\"" + jsonVarName + "\""
            }

            if (!attribute.native) {
                if (jsonVarName !== null) {
                    method += ", "
                }
                method += typeName + ".class"
            }

            method += ")"

            return method;

        } catch (Exception e) {
            e.printStackTrace();
        }
        return ""
    }

    def static getDataOrNativeTypeFromJsonCreatorMethodForFunctionality(Attribute attribute, String jsonVarName) {
        try {

            var singleNativePreamble = '''«jsonVarName» == null ? null : «jsonVarName».trim().isEmpty() ? null : «jsonVarName».equals("null") ? null : '''
            if (attribute.singleText) {
                return '''«singleNativePreamble»«jsonVarName».substring(1, «jsonVarName».length() - 1)''';
            }
            if (attribute.singleDigit) {
                return '''«singleNativePreamble»Long.parseLong(«jsonVarName»)'''
            }
            if (attribute.singleRealDigit) {
                return '''«singleNativePreamble»Double.parseDouble(«jsonVarName»)'''
            }
            if (attribute.singleTruth) {
                return '''«singleNativePreamble»Boolean.parseBoolean(«jsonVarName»)'''
            }

            var typeName = attribute.name

            if (!attribute.native) {
                typeName = typeName.toFirstUpper
                if (attribute.enumerator) {
                    typeName += "Enumerator"
                }
            }

            if (!attribute.unknown && attribute.many) {
                typeName += "Series"
            }

            var method = "Tools.FACTORY_" + typeName.toStaticFieldNameForTools

            if (!attribute.native) {
                method = typeName
            }
            return method + ".fromJson(" + jsonVarName + ")"
        } catch (Exception e) {
            e.printStackTrace();
        }
        return ""
    }

    def static shouldImportTools(Functionality functionality) {
        functionality.input.shouldImportTools(true)
    }

    def static shouldImportTools(Attribute attribute) {
        return attribute.shouldImportTools(false)
    }

    def static shouldImportTools(Attribute attribute, boolean alsoUnknown) {
        return attribute !== null &&
            (attribute.email ||
            (attribute.native &&
            attribute.many &&
            !attribute.unknown) ||
            (attribute.unknown && alsoUnknown)
        )
    }
}
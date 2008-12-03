package flight.utils
{
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public class Type
	{
		private static var typeCache:Dictionary = new Dictionary();
		private static var inheritanceCache:Dictionary = new Dictionary();
		private static var propertyCache:Dictionary = new Dictionary();
		private static var methodCache:Dictionary = new Dictionary(); 
		
		public function Type()
		{
		}
		
		public static function isType(value:Object, type:Class):Boolean
		{
			if( !(value is Class) )
				return value is type;
			
			if(value == type)
				return true;
			
			var inheritance:XMLList = describeInheritance(value);
			return Boolean( inheritance.(@type == getQualifiedClassName(type)).length() > 0 );
		}
		
		public static function getPropertyType(value:Object, property:String):Class
		{
			if( !(property in value) )
				return null;
			
			// retrieve the correct property type from the property list
			var typeName:String = describeProperties(value).(@name == property)[0].@type;
			if(!typeName)
				return null;
			
			return getDefinitionByName(typeName) as Class;
		}
		
		public static function getTypeProperty(value:Object, type:Class):String
		{
			var typeName:String = getQualifiedClassName(type);
			
			// retrieve the correct type property from the property list
			var propList:XMLList = describeProperties(value).(@type == typeName);
			
			return (propList.length() > 0) ? propList[0].@name : "";
		}
		
		public static function describeType(value:Object):XML
		{
			if( !(value is Class) )
				value = getType(value);
			
			if(typeCache[value] == null)
				typeCache[value] = flash.utils.describeType(value);
			
			return typeCache[value];
		}
		
		public static function describeInheritance(value:Object):XMLList
		{
			if( !(value is Class) )
				value = getType(value);
			
			if(inheritanceCache[value] == null)
				inheritanceCache[value] = describeType(value).factory.*.(localName() == "extendsClass" || localName() == "implementsInterface");
			return inheritanceCache[value];
		}
		
		public static function describeProperties(value:Object, metadata:String = null):XMLList
		{
			if( !(value is Class) )
				value = getType(value);
			
			if(propertyCache[value] == null)
				propertyCache[value] = describeType(value).factory.*.(localName() == "accessor" || localName() == "variable");
			
			if(metadata == null)
				return propertyCache[value];
			
			if(propertyCache[metadata] == null)
				propertyCache[metadata] = new Dictionary();
			if(propertyCache[metadata][value] == null)
				propertyCache[metadata][value] = propertyCache[value].(child("metadata").(@name == metadata).length() > 0);
			return propertyCache[metadata][value];
		}
		
		public static function describeMethods(value:Object, metadata:String = null):XMLList
		{
			if( !(value is Class) )
				value = getType(value);
			
			if(methodCache[value] == null)
				methodCache[value] = describeType(value).factory.method;
			
			if(metadata == null)
				return methodCache[value];
			
			if(methodCache[metadata] == null)
				methodCache[metadata] = new Dictionary();
			if(methodCache[metadata][value] == null)
				methodCache[metadata][value] = methodCache[value].(child("metadata").(@name == metadata).length() > 0);
			return methodCache[metadata][value];
		}
		
	}
}
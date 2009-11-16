package flight.services.net
{
	import flash.net.ObjectEncoding;
	import flash.utils.ByteArray;
	
	public class AMFMessage
	{
		public var version:uint = ObjectEncoding.AMF3;
		public var headers:Array = new Array();
		public var bodies:Array = new Array();
		
		protected var references:Array = new Array();
		
		public function AMFMessage()
		{
		}
		
		public function get dataObjects():Array
		{
			var values:Array = new Array();
			if (bodies !== null) {
				for each (var body:Object in bodies) {
					values.push((body as AMFBody).data);
				}					
			}
			return values;
		}
		
		public function get firstDataObject():Object
		{
			var value:Object = null;
			if (bodies !== null && bodies.length > 0) {
				value = bodies[0];
				if (value.hasOwnProperty('data')) {
					value = value.data;
				}					
			}
			return value;
		}
		
		public function addHeader(name:String=null, mustUnderstand:Boolean=false, data:Object=null):void
		{
			var amfHeader:AMFHeader = new AMFHeader();
				amfHeader.headerName = name;
				amfHeader.mustUnderstand = mustUnderstand;
				amfHeader.data = data;
				
			headers.push(amfHeader);
		}
		
		public function addBody(targetURI:String=null, responseURI:String=null, data:Object=null):void
		{
			var amfBody:AMFBody = new AMFBody();
				amfBody.targetURI = targetURI;
				amfBody.responseURI = responseURI;
				amfBody.data = data;
				
			bodies.push(amfBody);
		}
		
		public function readMessage(src:ByteArray):void
		{
 			version = ObjectEncoding.AMF0;
			headers = new Array();
			bodies = new Array();
			references = new Array();
			
			// Since this is an AMF message packet, 
			// start processing objects using the AMF0 encoding 
			// until we encounter an AMF0_AMF3 promotion type marker
			// as per the AMF3 and AMF0 file format documents, 
			// AMF serialized objects are of type AMF0 until the special AMF0_AMF3 marker is encountered.
			// once this marker has been found, we can switch to AMF3 encoding.
			var orgObjectEncoding:uint = src.objectEncoding;
			src.objectEncoding = ObjectEncoding.AMF0;
			
			// parse version
			version = src.readUnsignedShort();
			if (version != ObjectEncoding.AMF0 && version != ObjectEncoding.AMF3) {
				// unknown AMF version
				// throw new Error("Unknown AMF Version: " + version);
				
				src.position -= 2;
				
				// see if it's an amf object that we can parse
				var attempResult:Object = new Object();
				if (attemptReadObject(src, attempResult)) {
					var amfBody:AMFBody = new AMFBody();
					amfBody.data = attempResult.data;
					bodies.push(amfBody);
					return;
				}
				
				src.position += 2;
			}
			
			// parse headers
			var numHeaders:uint = src.readUnsignedShort();
			while (numHeaders--) {
				headers.push(readHeader(src));
			}
			
			// parse bodies
			var numBodies:uint = src.readUnsignedShort();
			while (numBodies--) {
				bodies.push(readBody(src));
			}			
			
			// restore the original object encoding, just to be nice.  
			// callers won't expect a function to be changing the encoding of a ByteArray.
			src.objectEncoding = orgObjectEncoding;
		}		
		
		public function writeMessage(dst:ByteArray):void
		{
			// all messages start with AMF0, subsequent bodies may switch to AMF3 later
			dst.objectEncoding = ObjectEncoding.AMF0;
			
			// write message object encoding version
			dst.writeShort(ObjectEncoding.AMF3);
			
			// write headers
			dst.writeShort(headers.length);
			for each (var header:AMFHeader in headers) {
				writeHeader(dst, header);
			}
			
			// write bodies
			dst.writeShort(bodies.length);
			for each (var body:AMFBody in bodies) {
				writeBody(dst, body);
			}			
		}
		
		protected function readHeader(src:ByteArray):AMFHeader
		{
			var amfHeader:AMFHeader = new AMFHeader();
			
			try {
				amfHeader.headerName = src.readUTF();
				amfHeader.mustUnderstand = (src.readByte() != 0); 
				var length:uint = src.readUnsignedInt(); // ignore header length
				amfHeader.data = readTypeMarkerDataObject(src);
			} catch (err:Error) {}
			
			return amfHeader;
		}
		
		protected function writeHeader(dst:ByteArray, amfHeader:AMFHeader):void
		{
			dst.writeUTF(amfHeader.headerName);
			dst.writeByte(amfHeader.mustUnderstand? 1: 0);
			dst.writeUnsignedInt(AMFConstants.AMF_UNKNOWN_CONTENT_LENGTH);
			writeTypeMarkerDataObject(dst, amfHeader.data);
		}
		
		protected function readBody(src:ByteArray):AMFBody
		{
			var amfBody:AMFBody = new AMFBody();
			
			try {
				amfBody.targetURI = src.readUTF();
				amfBody.responseURI = src.readUTF();
				var length:uint = src.readUnsignedInt(); // ignore body length	
				amfBody.data = readTypeMarkerDataObject(src);
			} catch (err:Error) {}
			
			return amfBody;
		}
		
		protected function writeBody(dst:ByteArray, amfBody:AMFBody):void
		{
			if (amfBody.targetURI == null) { amfBody.targetURI = ''; }
			if (amfBody.responseURI == null) { amfBody.responseURI = ''; }

			dst.writeUTF(amfBody.targetURI);
			dst.writeUTF(amfBody.responseURI);
			dst.writeUnsignedInt(AMFConstants.AMF_UNKNOWN_CONTENT_LENGTH);
			
			// if the encoding isn't AMF3 yet, switch to it.
			if (dst.objectEncoding !== ObjectEncoding.AMF3) {
				dst.writeByte(AMFConstants.AMF0_AMF3);
				dst.objectEncoding = ObjectEncoding.AMF3;			
			}
			
			writeTypeMarkerDataObject(dst, amfBody.data);
		}

		protected function readTypeMarkerDataObject1(src:ByteArray):Object
		{
			var typeMarker:uint = src.readByte();
			if (typeMarker == AMFConstants.AMF0_AMF3) {
				// we found the special AMF0_AMF3 marker, switch to AMF3 encoding.
				src.objectEncoding = ObjectEncoding.AMF3;
			} else {
				// no special marker found, pretend this didn't happen (waving hands). 
				src.position--;
			}
			return src.readObject();
		}
		
		protected function readTypeMarkerDataObject(src:ByteArray):Object
		{
			var data:Object = null;
			
			try {
				var typeMarker:uint = src.readByte();
			
				if (src.objectEncoding == ObjectEncoding.AMF0) {
					switch (typeMarker) {
						case AMFConstants.AMF0_AMF3:
					   		src.objectEncoding = ObjectEncoding.AMF3;
					   		data = readTypeMarkerDataObject(src);
					   		break;

						case AMFConstants.AMF0_NUMBER:	
							data = src.readDouble();
							break;
							
						case AMFConstants.AMF0_BOOLEAN:    	   
							data = src.readBoolean();
							break;
							 
					    case AMFConstants.AMF0_STRING:
					    	data = src.readUTF();
					    	break;
					    	      	
					    case AMFConstants.AMF0_OBJECT:
					    	src.position--;
					    	data = src.readObject();
					    	references.push(data);
					    	break;
					          	
					    case AMFConstants.AMF0_MOVIECLIP:
					        src.position--;
					        data = src.readObject();
					    	break;
					        	
					    case AMFConstants.AMF0_NULL:
					    	data = null;
					    	break;
					    
					    case AMFConstants.AMF0_UNDEFINED:   
					    	data = undefined; 	
					    	break;
					    	
					    case AMFConstants.AMF0_REFERENCE:
					    	src.position--;
					    	var refIdx:uint = src.readShort();
					    	data = references[refIdx];
					    	break;
					    	       
					    case AMFConstants.AMF0_MIXEDARRAY:
					    	src.position--;
					    	data = src.readObject();
					    	references.push(data);
					    	break;
					          
					    case AMFConstants.AMF0_OBJECTTERM:
					    	src.position--;
					    	data = src.readObject();
					    	break;
					    	      
					    case AMFConstants.AMF0_ARRAY:          
					    	src.position--;
					    	data = src.readObject();
					    	break;
					    	 
					    case AMFConstants.AMF0_DATE:
					    	src.position--;
					    	data = src.readObject();
					    	break;
					    	            
					    case AMFConstants.AMF0_LONGSTRING:      
					    	data = src.readUTF();
					    	break;
					    	
					    case AMFConstants.AMF0_UNSUPPORTED:
					    	src.position--;	
					    	data = src.readObject();
					    	break;
					    	     
					    case AMFConstants.AMF0_XML:       
					    	src.position--;    	
					    	data = src.readObject();
					    	break;
					    	
					    case AMFConstants.AMF0_TYPEDOBJECT:
					    	src.position--;
					    	data = src.readObject();
					    	references.push(data);
					    	break;	 
					}
				} else {
					switch (typeMarker) {
						case AMFConstants.AMF3_UNDEFINED:
							data = undefined;
							break;
							
						case AMFConstants.AMF3_NULL:
							data = null;
							break;
							          
						case AMFConstants.AMF3_BOOLEAN_FALSE:
							data = false;
							break;
							
						case AMFConstants.AMF3_BOOLEAN_TRUE:
							data = true;
							break;
						      	
						case AMFConstants.AMF3_INTEGER:
							data = readVariableLengthInt(src);
							break;
							           	
						case AMFConstants.AMF3_NUMBER:
							data = src.readDouble();
							break;
							            	
						case AMFConstants.AMF3_STRING:
							src.position--;
							data = src.readObject() as String;
							break;
							            	
						case AMFConstants.AMF3_DATE:
							src.position--;
							data = src.readObject();
							break;
	
						case AMFConstants.AMF3_ARRAY:
							src.position--;
							data = src.readObject();
							break;
							             	
						case AMFConstants.AMF3_OBJECT:   
							src.position--;
							data = src.readObject();
							break;
							         	
						case AMFConstants.AMF3_XML:               	
						case AMFConstants.AMF3_XMLSTRING:
							data = src.readUTF();
							break;
							         	
						case AMFConstants.AMF3_BYTEARRAY:
							src.position--;
							data = src.readObject() as ByteArray;
							break;
					}					
				}
			} catch (err:Error) {}
			
			return data;
		}
		
		protected function writeTypeMarkerDataObject(dst:ByteArray, data:Object):void
		{
			var typeMarker:uint = AMFConstants.determineTypeMarker(data, dst.objectEncoding);
			dst.writeByte(typeMarker);
			
			if (dst.objectEncoding == ObjectEncoding.AMF0) {
				switch (typeMarker)
				{
					case AMFConstants.AMF0_NUMBER:	
						dst.writeDouble(data as Number);
						break;
						
					case AMFConstants.AMF0_BOOLEAN:    	   
						dst.writeBoolean(data as Boolean);
						break;
						 
				    case AMFConstants.AMF0_STRING:
				    	dst.writeUTF(data as String);
				    	break;
				    	      	
				    case AMFConstants.AMF0_OBJECT:
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;
				          	
				    case AMFConstants.AMF0_MOVIECLIP:
				    	dst.position--;
				        dst.writeObject(data);
				    	break;
				        	
				    case AMFConstants.AMF0_NULL:
				    	break;
				    
				    case AMFConstants.AMF0_UNDEFINED:    	
				    	break;
				    	
				    case AMFConstants.AMF0_REFERENCE:
				    	dst.writeInt(data as int);
				    	break;
				    	       
				    case AMFConstants.AMF0_MIXEDARRAY:
				    	dst.position--;
				    	dst.writeInt(0);
				    	dst.writeObject(data);
				    	break;
				          
				    case AMFConstants.AMF0_OBJECTTERM:
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;
				    	      
				    case AMFConstants.AMF0_ARRAY:          
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;
				    	 
				    case AMFConstants.AMF0_DATE:
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;
				    	            
				    case AMFConstants.AMF0_LONGSTRING:      
				    	dst.writeUTF(data as String);
				    	break;
				    	
				    case AMFConstants.AMF0_UNSUPPORTED:
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;
				    	     
				    case AMFConstants.AMF0_XML:           	
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;
				    	
				    case AMFConstants.AMF0_TYPEDOBJECT:
				    	dst.position--;
				    	dst.writeObject(data);
				    	break;	 
				    	   
				   	case AMFConstants.AMF0_AMF3:
				   		dst.objectEncoding = ObjectEncoding.AMF3;
				   		writeTypeMarkerDataObject(dst, data);
				   		break;
				}
			} else {
				switch (typeMarker) {
					case AMFConstants.AMF3_UNDEFINED:
					case AMFConstants.AMF3_NULL:          
					case AMFConstants.AMF3_BOOLEAN_FALSE:
					case AMFConstants.AMF3_BOOLEAN_TRUE:
						break;
					      	
					case AMFConstants.AMF3_INTEGER:
						writeVariableLengthInt(dst, data as uint);
						break;
						           	
					case AMFConstants.AMF3_NUMBER:
						dst.writeDouble(data as Number);
						break;
						            	
					case AMFConstants.AMF3_STRING:
						dst.position--;
						dst.writeObject(data as String);
						break;
						            	
					case AMFConstants.AMF3_DATE:
						dst.position--;
						dst.writeObject(data);
						break;

					case AMFConstants.AMF3_ARRAY:
						dst.position--;
						dst.writeObject(data);
						break;
						             	
					case AMFConstants.AMF3_OBJECT:   
						dst.position--;
						dst.writeObject(data);
						break;
						         	
					case AMFConstants.AMF3_XML:               	
					case AMFConstants.AMF3_XMLSTRING:
						dst.writeUTF(data as String);
						break;
						         	
					case AMFConstants.AMF3_BYTEARRAY:
						dst.position--;
						dst.writeObject(data as ByteArray);							
						break;
				}
			}
			
		}
		
		protected function readVariableLengthInt(src:ByteArray):Object
		{
			const maxBytes:uint = 4;
			
			var value:uint = 0;
			var bytesRead:uint = 0;			
			var byteRef:uint = 0;
			
			try {
				byteRef = src.readByte();
				while (((byteRef & 0x80) != 0) && bytesRead < maxBytes) {
					value <<= 7;
					value |= (value & 0x7f);
					byteRef = src.readByte();
				}
			} catch (err:Error) {}
			
			if (bytesRead < maxBytes) {
				value <<= 7;
				value |= byteRef;
			} else {
				value <<= 8;
				value |= byteRef;
				
				if ((value & 0x10000000) != 0) {
					value |= (~0xFFFFFFF);
				}
			}
			
			return value;
		}
		
		protected function writeVariableLengthInt(dst:ByteArray, value:uint):void
		{
			// can write variable length negative or positive integers (up to 4 bytes total)
			// otherwize use writeDouble
			if ((value & 0xffffff80) == 0) {
	            dst.writeByte(value & 0x7f);
	        } else  if ((value & 0xffffc000) == 0 ) {
	            dst.writeByte((value >>  7) | 0x80);
	            dst.writeByte(value & 0x7f);
	        } else if ((value & 0xffe00000) == 0) {
	            dst.writeByte((value >> 14) | 0x80);
	            dst.writeByte((value >>  7) | 0x80);
	            dst.writeByte(value & 0x7f);
	        } else {
		        dst.writeByte((value >> 22) | 0x80);
		        dst.writeByte((value >> 15) | 0x80);
		        dst.writeByte((value >>  8) | 0x80);
		        dst.writeByte(value & 0xff);
			}
		}
		
		protected function attemptReadObject(src:ByteArray, result:Object):Boolean
		{
			// if successful, put the response data on result.data and return true
			var success:Boolean = false;
			var posOrg:uint = src.position;
			var objectEncodingOrg:uint = src.objectEncoding;
				
			try {
				src.objectEncoding = ObjectEncoding.AMF3;
				result.data = src.readObject();
				success = (src.bytesAvailable == 0);				
			} catch (err:Error) {}
			
			if (!success) {
				src.position = posOrg;
				src.objectEncoding = objectEncodingOrg;
				result.data = null;
			}
			
			return success;
		}
	}
}


import flash.utils.ByteArray;
import flash.net.ObjectEncoding;
import flash.xml.XMLDocument;


class AMFHeader
{
	public var headerName:String;
	public var mustUnderstand:Boolean = false;
	public var data:Object;
}

class AMFBody
{
	public var targetURI:String;
	public var responseURI:String;
	public var data:Object;
}

class AMFConstants
{
	public static const AMF_UNKNOWN_CONTENT_LENGTH:int	= -1;
	
	public static const AMF0_NUMBER:uint    	        = 0x00;
    public static const AMF0_BOOLEAN:uint    	       	= 0x01;
    public static const AMF0_STRING:uint      	      	= 0x02;
    public static const AMF0_OBJECT:uint      	      	= 0x03;
    public static const AMF0_MOVIECLIP:uint    	     	= 0x04;
    public static const AMF0_NULL:uint         	     	= 0x05;
    public static const AMF0_UNDEFINED:uint    	     	= 0x06;
    public static const AMF0_REFERENCE:uint         	= 0x07;
    public static const AMF0_MIXEDARRAY:uint        	= 0x08;
    public static const AMF0_OBJECTTERM:uint        	= 0x09;
    public static const AMF0_ARRAY:uint             	= 0x0A;
    public static const AMF0_DATE:uint              	= 0x0B;
    public static const AMF0_LONGSTRING:uint        	= 0x0C;
    public static const AMF0_UNSUPPORTED:uint       	= 0x0E;
    public static const AMF0_XML:uint           	    = 0x0F;
    public static const AMF0_TYPEDOBJECT:uint	       	= 0x10;
   	public static const AMF0_AMF3:uint 					= 0x11;
   	
   	public static const AMF3_UNDEFINED:uint				= 0x00;
    public static const AMF3_NULL:uint              	= 0x01;
    public static const AMF3_BOOLEAN_FALSE:uint     	= 0x02;
    public static const AMF3_BOOLEAN_TRUE:uint      	= 0x03;
    public static const AMF3_INTEGER:uint           	= 0x04;
    public static const AMF3_NUMBER:uint            	= 0x05;
    public static const AMF3_STRING:uint            	= 0x06;
    public static const AMF3_XML:uint               	= 0x07;
    public static const AMF3_DATE:uint              	= 0x08;
    public static const AMF3_ARRAY:uint             	= 0x09;
    public static const AMF3_OBJECT:uint            	= 0x0A;
    public static const AMF3_XMLSTRING:uint         	= 0x0B;
    public static const AMF3_BYTEARRAY:uint         	= 0x0C;
    
    public static function determineTypeMarker(data:*, objectEncoding:uint):uint
	{
		if (objectEncoding == ObjectEncoding.AMF0) {
			return determineTypeMarker_amf0(data);
		} else if (objectEncoding == ObjectEncoding.AMF3) {
			return determineTypeMarker_amf3(data);
		}
		return AMF0_UNSUPPORTED;
	}
	
	protected static function determineTypeMarker_amf0(data:*):uint
	{
		var typeMarker:uint = AMF0_UNSUPPORTED;
		 
		if (data === null) {
			typeMarker = AMF0_NULL;
		} else if (data is undefined) {
			typeMarker = AMF0_UNDEFINED;
		} else if (data is Number || data is int || data is uint) {
		   	typeMarker = AMF0_NUMBER;
		} else if (data is Boolean) {
			typeMarker = AMF0_BOOLEAN;
		} else if (data is String) {
			typeMarker = AMF0_STRING;
		} else if (data is Array) {
			typeMarker = AMF0_ARRAY;
		} else if (data is Date) {
			typeMarker = AMF0_DATE;
		} else if (data is Object) {
			typeMarker = AMF0_OBJECT;
		}
		
		return typeMarker;
	}
	
	protected static function determineTypeMarker_amf3(data:*):uint
	{
		var typeMarker:uint = AMF3_OBJECT;
		
		if (data === null) {
			typeMarker = AMF3_NULL;
		} else if (data === undefined) {
			typeMarker = AMF3_UNDEFINED;
		} else  if (data is int || data is uint) {
			var num:Number = (data as Number);
			if (num > 0xFFFFFFF || num < -268435456) {
				typeMarker = AMF3_NUMBER;
			} else {
				typeMarker = AMF3_INTEGER;
			} 
		} else if (data is Number) {
		   	typeMarker = AMF3_NUMBER;
		} else if (data is Boolean) {
			typeMarker = (data as Boolean)? AMF3_BOOLEAN_TRUE: AMF3_BOOLEAN_FALSE;
		} else if (data is String) {
			typeMarker = AMF3_STRING;
		} else if (data is Array) {
			typeMarker = AMF3_ARRAY;
		} else if (data is Date) {
			typeMarker = AMF3_DATE;
		} else if (data is ByteArray) {
			typeMarker = AMF3_BYTEARRAY;
		} else if (data is XML || data is XMLDocument) {
			typeMarker = AMF3_XMLSTRING			
		} else if (data is Object) {
			typeMarker = AMF3_OBJECT;
		}
		
		return typeMarker;
	}
}


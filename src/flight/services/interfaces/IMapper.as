/**
 * Object Relational Map Pattern: Maps objects to relational databases. 
 * In other words, it is used to encapsulate physical data in logical 
 * objects. A typical mapping would map a table to a class, a row to 
 * an object and a column to an attribute. 
 */
package flight.services.interfaces
{
	public interface IMapper
	{
		function map(resource:Object, params:Object=null):String;
	}
}
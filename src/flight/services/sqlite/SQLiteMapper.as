package flight.services.sqlite
{
	import flight.services.abstracts.AbstractMapper;

	public class SQLiteMapper extends AbstractMapper
	{
		public var dbPath:String = '';
		
		public function SQLiteMapper(dbPath:String)
		{
			this.dbPath = dbPath;
		}
		
		override public function map(resource:Object, params:Object=null):String
		{
			var location:String = getLocation(resource);
			if(!location) {
				throw new Error('No resource found for ' + resource);
			}
			return location;
		}
		
	}
}
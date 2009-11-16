package flight.services.abstracts
{
	import flight.utils.ObjectEditor;
	import flight.utils.getClassName;
	import flight.vo.ValueObject;
	
	import flx.service.interfaces.IModel;

	public class AbstractModel extends ValueObject implements IModel
	{
		public function AbstractModel()
		{
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function get isNew():Boolean
		{
			if('id' in this) {
				return this['id'] > 0;
			}
			
			return false;
		}
		
		public function set isNew(value:Boolean):void
		{
			if('id' in this && value) {
				this['id'] = null;
			}
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function serialize():Object
		{
			return this;
		}
		
		/**
		 * 
		 * @param value
		 * 
		 */		
		public function unserialize(value:Object):void
		{
			ObjectEditor.merge(value, this);
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function validate():Boolean
		{
			return true;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function toString():String
		{
			return getClassName(this);
		}
		
	}
}
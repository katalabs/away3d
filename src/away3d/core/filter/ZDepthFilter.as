﻿package away3d.core.filter{	import away3d.arcane;	import away3d.core.render.*;		use namespace arcane;	    /**    * Defines a maximum z value for rendering primitives    */    public class ZDepthFilter implements IPrimitiveFilter    {    	private var _order:Vector.<uint>;		private var _maxZ:Number;		private var _minT:Number;    			/**		 * Creates a new <code>ZDepthFilter</code> object.		 *		 * @param	maxZ	A maximum allowed depth value for drawing primitives.		 */		function ZDepthFilter(maxZ:Number){			_maxZ = maxZ;		}        		/**		 * @inheritDoc		 */        public function filter(renderer:Renderer):void        {
			_order = renderer._order;
			_minT = renderer._coeffScreenT/_maxZ;			var i:uint;
			for each (i in _order) {
				if (renderer._screenTs[_order[i]] < _minT) {					_order.splice(i);					break;				}			}        }				/**		 * Used to trace the values of a filter.		 * 		 * @return A string representation of the filter object.		 */        public function toString():String        {            return "ZDepthFilter";        }    }}
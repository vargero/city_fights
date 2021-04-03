pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- main
console=""
current_state=nil
current_scene=nil

function _init()
	palt(14,true)
	palt(0,false)

	local m=create_map(10,10)
	local t={
		make_character(4,4,72,"jeff",make_movement("x",3)),
		make_character(3,1,70,"bob",make_movement("x",4)),
		make_character(7,2,71,"karl",make_movement("x",2))
	}

	current_scene=create_scene(m,t)
end

function _update()
	current_scene:update()
end

function _draw()
	cls(12)
	
	current_scene:draw()
	print(console,current_scene.camera.x,current_scene.camera.y,3)
end
-->8
-- scene/map
function create_scene(map,team)
	return {
		camera=v(0,0),
		map=map,
		team=team,
		current_state=select_character(team),
		draw=function(s)
			s.map:draw()
			for player in all(s.team)do
				player:draw()
			end
			camera(s.camera.x,s.camera.y)
		end,
		update=function(s)
			if(s.current_state!=nil)s.current_state:update()
		end,
		state_callback=function(s,p)
			return function()
				s:update_state(p)
			end
		end,
		update_state=function(s,p)
			s.current_state=p
		end
	}
end

function create_map(w,h)
	return {
		width=w,
		height=h,
		focused_tile=nil,
		focused_tile_state=true,
		highlighted_tiles=nil,
		draw=function(s)
			for i=0,s.width,1do
				for j=0,s.height,1do
					if(i==0or j==0)then
						local coords=cartoiso(i,j)
						spr(96,coords.x,coords.y-23,3,3)
						spr(3,coords.x,coords.y-29,3,3,i==0)
					end
				end
			end
			for i=0,s.width-1,1do
				for j=0,s.height-1,1do
					local coords=cartoiso(i,j)
					spr(0,coords.x,coords.y,3,2)
				end	
			end
			if(s.highlighted_tiles!=nil)then
				foreach(s.highlighted_tiles,function(o)
					local coords=cartoiso(o.x,o.y)
					spr(9,coords.x,coords.y,3,2)
				end)
			end
			if(s.focused_tile!=nil)then
				local sn=12
				if(s.focused_tile_state)sn-=6
				local coords=cartoiso(s.focused_tile.x,s.focused_tile.y)
				spr(sn,coords.x,coords.y,3,2)
			end
		end,
		clear_tiles=function(s)
			s.focused_tile=nil
			s.highlighted_tiles=nil
		end,
		focus_tile=function(s,v,vl)
			if(vl==nil)vl=true
			if(v.x>=0 and v.x<s.width and v.y>=0 and v.y<s.height)then
				s.focused_tile=v
				s.focused_tile_state=vl
			end
		end,
		highlight_tiles=function(s,o,r)
			s.highlighted_tiles={}
			add(s.highlighted_tiles,v(o.x,o.y))
			for i=1,r do
				-- x
				add(s.highlighted_tiles,v(o.x+i,o.y+i))
				add(s.highlighted_tiles,v(o.x+i,o.y-i))
				add(s.highlighted_tiles,v(o.x-i,o.y+i))
				add(s.highlighted_tiles,v(o.x-i,o.y-i))
				-- +
				add(s.highlighted_tiles,v(o.x,o.y+i))
				add(s.highlighted_tiles,v(o.x,o.y-i))
				add(s.highlighted_tiles,v(o.x+i,o.y))
				add(s.highlighted_tiles,v(o.x-i,o.y))
			end
			local invalids={}
			foreach(s.highlighted_tiles,function(h)
				if(h.x<0 or h.x>=s.width or h.y<0 or h.y>=s.height)add(invalids,h)
			end)

			foreach(invalids,function(i)
				del(s.highlighted_tiles,i)
			end)
		end
	}
end
-->8
-- char/team
function make_character(x,y,s,n,m)
	return {
		name=n,
		sprite=s,
		position=v(x,y),
		movement=m,
		update=function(s)end,
		draw=function(s)
			local coords=cartoiso(s.position.x,s.position.y)
			spr(s.sprite,coords.x+(tile_width/2)+2,coords.y-(tile_width*0.75),1,2)
		end
	}
end

function make_movement(t,r)
	return {
		type=t,
		radius=r
	}
end
-->8
-- game phases
select_character=function(t,s)
	return {
		selected_index=s,
		update=function(s)
			local c=false
			if(s.selected_index==nil)then
				s.selected_index=0
				c=true
			elseif(btnp(0))then
				s.selected_index-=1
				c=true
			elseif(btnp(1))then
				s.selected_index+=1
				c=true
			end

			if(s.selected_index<1)s.selected_index=#t
			if(s.selected_index>#t)s.selected_index=1
			
			local p=t[s.selected_index]
			current_scene.map:focus_tile(p.position)
			
			if(c)then
				local c=current_scene:state_callback(select_character(t,s.selected_index))
				current_scene:update_state(camera_shift(p.position,c))
			end
			
			if(btnp(❎))current_scene:update_state(choose_action(t[s.selected_index]))
		end,
		draw=function(s)
		end
	}
end

choose_action=function(p,st)
	current_scene.map:highlight_tiles(p.position,p.movement.radius)
	if(st==nil)st=v(p.position.x,p.position.y)

	local is_valid=function(ori)
		local v=false
		foreach(current_scene.map.highlighted_tiles,function(o)
			if(o.x==ori.x and o.y==ori.y)v=true
		end)
		return v
	end

	return {
		selected_tile=st,
		update=function(s)
			local st0=v(s.selected_tile.x,s.selected_tile.y)
			if(btnp(0))then s.selected_tile.x-=1
			elseif(btnp(1))then s.selected_tile.x+=1
			elseif(btnp(2))then s.selected_tile.y-=1
			elseif(btnp(3))then s.selected_tile.y+=1
			end

			current_scene.map:focus_tile(s.selected_tile,is_valid(s.selected_tile))

			if(st0.x!=s.selected_tile.x or st0.y!=s.selected_tile.y)then
				local c=current_scene:state_callback(choose_action(p,s.selected_tile))
				current_scene:update_state(camera_shift(s.selected_tile,c))
			end
			if(btnp(❎)and is_valid(s.selected_tile))then
				local c=function()
					current_scene.map:clear_tiles()
					current_scene:update_state(select_character(current_scene.team))
				end
				current_scene:update_state(character_movement(p,s.selected_tile,c))
			end
		end,
		draw=function(s)
		end
	}
end

animation_phase=function(d,a,c,dr,f)
	local an=make_animator(d,a,c,f)
	return {
		update=function(s)
			an:update()
		end,
		draw=function(s)
			if(dr!=nil)dr()
		end
	}
end

character_movement=function(p,pos,c)
	local an=function(a)
		p.position.x=a(p.position.x,pos.x)
		p.position.y=a(p.position.y,pos.y)
	end
	return animation_phase(0.5,an,c)
end

character_hit=function(ch,c) -- need to figure out layer
	local ssp=51
	local an=function(a)
		ssp=a(51,53)
		console=ssp
	end
	local ha=cartoiso(ch.x,ch.y)
	return animation_phase(0.25,an,c,function()
		spr(ssp,ha.x+7,ha.y)
	end)
end

camera_shift=function(p,c)
	local cc=current_scene.camera
	local x0,y0=cc.x,cc.y
	local d=cartoiso(p.x,p.y)
	local x1,y1=d.x-60,d.y-64
	local an=function(a)
		current_scene.camera=v(a(x0,x1),a(y0,y1))
	end
	return animation_phase(0.25,an,c,nil,outquad)
end
-->8
-- utils
tile_width=12
function cartoiso(carx, cary)
	local x=(carx*tile_width)-(cary*tile_width)
	local y=(carx*tile_width/2)+(cary*tile_width/2)
	return v(x,y)
end

function v(x,y)
	if(x==nil)x=0
	if(y==nil)y=0
	return{x=x,y=y}
end
-->8
-- animation
function make_animator(d,a,c,f)
	if(f==nil)f=linear
	return{
		e=0,
		l=time(),
		update=function(s)
			if(s.e<=d)then
				local t=time()
	  			s.dt=t-s.l
	  			s.l=t
	  			s.e+=s.dt
	  			a(function(b,c)return f(s.e,b,c-b,d)end)
	  		else
	  			a(function(b,c)return c end)
	  			c()
	  		end
		end
	}
end

outquad=function(t,b,c,d)
  	t=t/d
  	return -c*t*(t-2)+b
end

linear=function(t,b,c,d)return c*t/d+b end

__gfx__
eeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeee22eeeeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeeeeeeeeeeee33eeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeee
eeeeeeeee005500eeeeeeeeeeeeeeeeee228822eeeeeeeeeeeeeeeeeebbeebbeeeeeeeeeeeeeeeeee33ee33eeeeeeeeeeeeeeeeee88ee88eeeeeeeeeeeeeeeee
eeeeeee0055555500eeeeeeeeeeeeee2288888822eeeeeeeeeeeeeebbeeeeeebbeeeeeeeeeeeeee333eeee333eeeeeeeeeeeeee88eeeeee88eeeeeeeeeeeeeee
eeeee00555555555500eeeeeeeeee22888888228822eeeeeeeeeebbeeeebbeeeebbeeeeeeeeee33ee3eeee3ee33eeeeeeeeee88eeee88eeee88eeeeeeeeeeeee
eee555500555555555500eeeeee228888882288888822eeeeeebbeeeeeeeeeeeeeebbeeeeee333eee3eeee3eee333eeeeee88eeeeeeeeeeeeee88eeeeeeeeeee
e5555555500555555555500ee2288888822888888228822eebbeeeebbeeeeeebbeeeebbee33ee3eee3eeee3eee3ee33ee88eeee88eeeeee88eeee88eeeeeeeee
055555555550055555555550288888822888888228888882beeebbeeeeebbeeeeebbeeeb3eeee3eee3eeee3eee3eeee38eee88eeeee88eeeee88eee8eeeeeeee
e0055555500550055555500ee2288228888882288888822eebbeeeebbeeeeeebbeeeebbee33ee3eee3eeee3eee3ee33ee88eeee88eeeeee88eeee88eeeeeeeee
eee005500555555005500eeeeee228888882288888822eeeeeebbeeeeeeeeeeeeeebbeeeeee333eee3eeee3eee333eeeeee88eeeeeeeeeeeeee88eeeeeeeeeee
eeeee00555555555500eeeeeeeeee22882288888822eeeeeeeeeebbeeeebbeeeebbeeeeeeeeee33ee3eeee3ee33eeeeeeeeee88eeee88eeee88eeeeeeeeeeeee
eeeeeee0055555555eeeeeeeeeeeeee2288888822eeeeeeeeeeeeeebbeeeeeebbeeeeeeeeeeeeee333eeee333eeeeeeeeeeeeee88eeeeee88eeeeeeeeeeeeeee
eeeeeeeee005555eeeeeeeeeeeeeeeeee228822eeeeeeeeeeeeeeeeeebbeebbeeeeeeeeeeeeeeeeee33ee33eeeeeeeeeeeeeeeeee88ee88eeeeeeeeeeeeeeeee
eeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeee22eeeeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeeeeeeeeeeee33eeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e224422eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
244444422eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
22244444422eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2442244444422eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
244442244444422eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2444444224444442eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2444444442244222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2444444444422442eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
2444444444442442eeeeeeeeeeeeeeeeeeeeeeeee6eeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e224444444442442eeeeeeeeeeeee6eeee6ee6eeeeeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee2244444442442eeeeeeeeeee6eeeeeeee6eeeeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee22444442442eeeeeeeeeeee6eeeeee6eeeeeeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeee224442442eeeeeeeeee6eeeeeee6ee6eeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee224222eeeeeeeeeeeeeeeeeeeeeeeeee6eeee6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0eeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000eeeeeee000000000eeeeeeeeeeeeeeeeeeeeeeeeeeee
000eeeeeeeeeeeeeeeeee000eeeeeeeee000000eeeeeeeeeeeeeeeeeeee8eeeeeee8eeeeee0ddddddddd0eeeee0ddddddddd0eeeeeeeeeeeeeeeeeeeeeeeeeee
04400eeeeeeeeeeeeee00440eeeeeee0044004400eeeeeeeeeeeeeeeee898eeeee888eeee0ddddddddddd0eee0ddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeeee
0444400eeeeeeeeee0099440eeeee00444400444400eeeeeee000eeeee888eeeee888eee0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
044444400eeeeee004494000eee004444440044444400eeeee888eeeee222eeeee222eee0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
04444444400ee00aa4400880e0044444444004444444400eee4ffeeeeeaffeeeeeaaaeee0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
044444444440044a40044840044444444006600444444440ee6f7eeeeefffeeeeefffeee0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
e0044444444004400bb4400e044444400666666004444440e77f77ee9982899e9999999e0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
eee00444444000044b400eee044440066666666660044440f77f77fe8982898e8999998e0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
eeeee00444400884400eeeee044006666666666666600440f77477fe8882888e8999998e0ddddddddddddd0e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeee0044008400eeeeeee000666666666666666666000477f774ef88288fef89998fe06ddddddddddd60e0ddddddddddddd0eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee000000eeeeeeeee066666666666666666666660e00000eee22222eee22922ee056ddddddddd650e06ddddddddddd60eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee67777eee88888eee88888ee055666666666550e056ddddddddd650eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee67e67eee5de5deee5de5deee0555555555550eee0566666666650eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee67e67eee5de5deee5de5deeee05555555550eeeee05555555550eeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffeffeee00e00eee00e00eeeee000000000eeeeeee000000000eeeeeeeeeeeeeeeeeeeeeeeeeeee
6eeeeeeeeeeeeeeeeeeeeeedeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666eeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
66666eeeeeeeeeeeeeeddddd0eeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
6666666eeeeeeeeeeddddddd000eeeeeeeeeeeeeeeeee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666eeeeeeddddddddd04400eeeeeeeeeeeeee00440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
66666666666eeddddddddddd0444400eeeeeeeeee0099440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666dddddddddddd044444400eeeeee004494000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666dddddddddddd04444444400ee00aa4400880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666dddddddddddd044444444440044a40044840eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666dddddddddddde0044444444004400bb4400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeee00444444000044b400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeee00444400884400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeeeee0044008400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeeeeeee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
666666666666ddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e66666666666dddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee666666666dddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee6666666dddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeee66666dddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee666dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee6deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee33eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee334433eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee3344444433eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeee33444444444433eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee334444444444444433eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee3344444444444444444433eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee344444444444444444444443eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee344444444444444444444443eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeed33444444444444444444335eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeddd334444444444444433555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeddddd3344444444443355555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeedddddd3344444433555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeedddddd334433555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeedddddd33555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeddddd55555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeddd555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__map__
000a020300010203000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1011000102031213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021101112132223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3031202122233233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000303132330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010800000c053000000000000000000000000000000000000c053000000000000000000000000000000000000c053000000000000000000000000000000000000c05300000000000000000000000000000000000
010800000677007771000000000000000000000000000000000000000000000000000777000000000000000007770067700000000000000000000000000000000000000000000000000000000000000000000000
a9080000265302b2001f53023200235302b2001e530292001a5302b2001353023200175302b20012530295002b5002b50023500295002b5002b50023500295002b5002b50023500295002b500000000000000000
__music__
02 00010244


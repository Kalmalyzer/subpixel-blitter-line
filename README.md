# Draw sub-pixel precise lines with the Amiga Blitter

## How to use

Call `SubPixelBlitterLine` or `SubPixelBlitterEdgeLine` with the following parameters:

```
; in	d0.w	x0 in fixed point
;	d1.w	y0 in fixed point
;	d2.w	x1 in fixed point
;	d3.w	y1 in fixed point
;	d4.w	bytes per row in bitplane
;	a0	bitplane
;	a6	$dff000
```

Ensure that the X- and Y-coordinates are specified in fixed point, with `SubPixelBlitterLine_Bits` fractional bits.

The routines provide 3 subpixel bits of precision by default; this works for rendering a large cube onto a 320x256 screen.
Shorter maximal line lengths support more subpixel bits.

## Performance

It takes a bit more setup, two extra multiplies -- perhaps twice as much CPU work as a non-subpixel-precise line drawer. The Blitter does the same amount of work as usual.

## About the algorithm

### Amiga hardware

The Amiga Blitter implements the Bresenham algorithm in hardware when drawing lines.

If you take a sneak peek in the WinUAE source code, specifically [blitter_line_proc()](https://github.com/tonioni/WinUAE/blob/3da2ed8232cd7cd11e00775df427d175d700d56e/blitter.cpp#L774-L810),
you can see the reverse engineered details:

Initialization:
```
BLTAPT = 4 * minordelta - 2 * majordelta
BLTAMOD = 4 * minordelta - 4 * majordelta
BLTBMOD = 4 * minordelta
BLTCON1.SIGN = (BLTAPT < 0)
```

Per-pixel stepping for the down-right, Y-major octant:
```
if (BLTCON1.SIGN)
	BLTAPT += BLTBMOD
else
	BLTAPT += BLTAMOD

if (!blitsign)
	step along minor axis

step along major axis

BLTCON1.SIGN = (BLTAPT < 0)
```

### Traditional Bresenham

[Bresenham's line algorithm](https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm#Line_equation)
relied on describing the line as a distance function, and then walking from pixel-center to pixel-center and incrementally
updating the current distance to the line. This is the function in pseudo code, for the down-right, Y-major octant:

```
distance = 0

for (count = 0 to majordelta)
{
	if (distance < 0)
	{
		x++
		distance -= majordelta
	}

	y++
	distance += minordelta
	
	putpixel(x, y)
}
```

### Bresenham with subpixel precision

Introducing subpixel precision to a line renderer means supporting non-integer X and Y coordinates, and making good use of the fractions.

To simplify the maths, we will shift the sampling location of each pixel to its lower-right corner.

Accounting for the fractions of the X and Y coordinates then involves a step of fractional length,
from the line's exact (x, y) start location to the pixel's sampling location. This affects the accumulated line distance. It may
also require moving one pixel along the minor axis.

Here is pseudocode for the down-right, Y-major octant:

```
prestep_x = (1 - x0.fraction)
prestep_y = (1 - y0.fraction)

distance = prestep_x * -majordelta + prestep_y * minordelta

if (distance < 0)
{
	x++
	distance -= majordelta
}

putpixel(x.integer, y.integer)

for (count = 1 to majordelta)
{
	if (distance < 0)
	{
		x++
		distance -= majordelta
	}

	y++
	distance += minordelta
	
	putpixel(x.integer, y.integer)
}
```

### Bresenham with subpixel precision with the Amiga Blitter

A few tweaks are necessary to implement this on the Amiga.

All calculations need to be changed to fixed point. This requires shifting up all calculations by the number of subpixel bits.
The Blitter performs the distance arithmetic using 16-bit signed math. This places a limit on the max line length; longer lines support
fewer subpixel bits.

The Blitter hardware will always put the first pixel at the start location; that is, the putpixel() is at the top of the for-loop in the
pseudocode. We can take advantage of this: If we move the start location up by 1 pixel, and [discarding the first pixel drawn by pointing BLTDPT to an off-screen memory location](http://eab.abime.net/showpost.php?p=206412&postcount=6),
the Blitter will handle the re-normalization when (distance < 0) at the first sampling location.

## Known problems

The current agorithm does not map perfectly to the ONEDOT mode. For X-major lines, with ONEDOT mode active, the Blitter hardware will
only draw a single dot per row -- it will draw the first dot that is visited on each line. The prestepping logic as presented here,
on the other hand, expects the last dot on each row to be drawn.
It might be possible to correct for this by further adjustment of the input parameters.


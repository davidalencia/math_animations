using Images
using ResumableFunctions
using Interpolations
import ImageMagick
using Images
using VideoIO
using FreeTypeAbstraction
using ProgressMeter
import Humanize: digitsep


const char2digits = Dict('0'=>(0,0,0),
    '1'=>(0,0,1),
    '2'=>(0,1,0),
    '3'=>(0,1,1),
    '4'=>(1,0,0),
    '5'=>(1,0,1),
    '6'=>(1,1,0),
    '7'=>(1,1,1),
    '8'=>(0,0,1),
    '9'=>(1,0,0,1))
const on_color = colorant"lightsteelblue"
const off_color = colorant"steelblue3"

const face = FTFont("OpenSans-Bold.ttf")


function block2img(block, dim::Tuple{Int, Int})
  img = zeros(RGB{N0f8}, dim...)
  len = *(dim...)
  i = 1
  j = 1
  while i<len
      digits = RGB{N0f8}.(char2digits[block[j]])
      j+=1
      maxsize = min(size(digits,1), len-i)
      digits = digits[1:maxsize]
      img[i:i+maxsize-1] .= digits
      i+=maxsize
  end
  return img
end

function text2image(text;x=50)
  image = zeros(RGB{N0f8}, 20, 200)
  renderstring!(image, text, face, 12, 10, 100, halign=:hcenter, valign=:vcenter)
  return image
end

@resumable function fileReader()
  file = open("pi-million.txt","r")
  while !eof(file)
      @yield read(file, Char)
  end
  close(file)
end

function style(img::Matrix{RGB{N0f8}})
  colored = copy(img)
  black = colorant"black"
  white = colorant"white"
  for ix in LinearIndices(colored)
      if(colored[ix]==black)
          colored[ix] = off_color
      else
          colored[ix] = on_color
      end
  end
  return imresize(colored, (200, 200), method=BSpline(Constant()))
end

function search(img::Matrix{RGB{N0f8}}, title="video")
  function styleNtext(img::Matrix{RGB{N0f8}}, chars, ix)
      return vcat(text2image("...$(String(chars))...   #$(digitsep(ix))"), style(img))
  end
  len = *(size(img)...)
  charlen = convert(Int, ceil(len/3))
  iter = fileReader()
  chars = [iter() for _ in 1:charlen]
  i = 1
  value = block2img(chars,size(img))
  p = Progress(1_000_000, 1) 
  encoder_options = (crf=23, preset="medium")
  framerate=24
  open_video_out("$title.mp4", styleNtext(value, vcat(['3','.'],chars), i), framerate=framerate, encoder_options=encoder_options) do writer
      while true
          value = block2img(chars,size(img))
          write(writer, styleNtext(value, chars, i))
          i += 1
          if(value == img)
              break;
          end
          popfirst!(chars)
          newchar = iter()
          if(isnothing(newchar)) 
              return "supersad"
          end
          push!(chars, newchar)
          next!(p)
      end
      lastblock =styleNtext(value, chars, i)
      for _ in 1:50
          write(writer, lastblock)
      end
  end
end

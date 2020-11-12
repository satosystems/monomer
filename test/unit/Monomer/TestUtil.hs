module Monomer.TestUtil where

import Control.Monad.State
import Data.Default
import Data.Maybe
import Data.Text (Text)
import Data.Sequence (Seq)
import System.IO.Unsafe

import qualified Data.Map.Strict as M
import qualified Data.Text as T
import qualified Data.Sequence as Seq

import Monomer.Core
import Monomer.Event
import Monomer.Graphics
import Monomer.Main.Handlers
import Monomer.Main.Util

testW :: Double
testW = 640

testH :: Double
testH = 480

testWindowSize :: Size
testWindowSize = Size testW testH

testWindowRect :: Rect
testWindowRect = Rect 0 0 testW testH

mockTextMetrics :: Font -> FontSize -> TextMetrics
mockTextMetrics font fontSize = TextMetrics {
  _txmAsc = 15,
  _txmDesc = 5,
  _txmLineH = 20
}

mockTextSize :: Font -> FontSize -> Text -> Size
mockTextSize font size text = Size width height where
  width = fromIntegral $ T.length text * 10
  height = 20

mockGlyphsPos :: Font -> FontSize -> Text -> Seq GlyphPos
mockGlyphsPos font fontSize text = glyphs where
  w = 10
  chars = Seq.fromList $ T.unpack text
  mkGlyph idx chr = GlyphPos {
    _glpGlyph = chr,
    _glpXMin = fromIntegral idx * w,
    _glpXMax = (fromIntegral idx + 1) * w,
    _glpW = w
  }
  glyphs = Seq.mapWithIndex mkGlyph chars

mockRenderText :: Point -> Font -> FontSize -> Text -> IO ()
mockRenderText point font size text = return ()

mockRenderer :: Renderer
mockRenderer = Renderer {
  beginFrame = \w h -> return (),
  endFrame = return (),
  -- Path
  beginPath = return (),
  closePath = return (),
  -- Context management
  saveContext = return (),
  restoreContext = return (),
  -- Overlays
  createOverlay  = \overlay -> return (),
  renderOverlays = return (),
  -- Scissor operations
  setScissor = \rect -> return (),
  resetScissor = return (),
  -- Strokes
  stroke = return (),
  setStrokeColor = \color -> return (),
  setStrokeWidth = \width -> return (),
  -- Fill
  fill = return (),
  setFillColor = \color -> return (),
  setFillLinearGradient = \p1 p2 c1 c2 -> return (),
  -- Drawing
  moveTo = \point -> return (),
  renderLine = \p1 p2 -> return (),
  renderLineTo = \point -> return (),
  renderRect = \rect -> return (),
  renderArc = \center radius angleStart angleEnd winding -> return (),
  renderQuadTo = \p1 p2 -> return (),
  renderEllipse = \rect -> return (),
  -- Text
  computeTextMetrics = mockTextMetrics,
  computeTextSize = mockTextSize,
  computeGlyphsPos = mockGlyphsPos,
  renderText = mockRenderText,

  -- Image
  addImage = \name action size imgData -> return (),
  updateImage = \name imgData -> return (),
  deleteImage = \name -> return (),
  existsImage = const True,
  renderImage = \name rect alpha -> return ()
}

mockWenv :: s -> WidgetEnv s e
mockWenv model = WidgetEnv {
  _weOS = "Mac OS X",
  _weRenderer = mockRenderer,
  _weTheme = def,
  _weAppWindowSize = testWindowSize,
  _weGlobalKeys = M.empty,
  _weFocusedPath = rootPath,
  _weOverlayPath = Nothing,
  _weCurrentCursor = CursorArrow,
  _weModel = model,
  _weInputStatus = def,
  _weTimestamp = 0
}

mockWenvEvtUnit :: s -> WidgetEnv s ()
mockWenvEvtUnit model = mockWenv model

instInit :: WidgetEnv s e -> WidgetInstance s e -> WidgetInstance s e
instInit wenv inst = newInst where
  WidgetResult _ _ inst2 = widgetInit (_wiWidget inst) wenv inst
  Size w h = _weAppWindowSize wenv
  vp = Rect 0 0 w h
  newInst = instResize wenv vp inst2

instUpdateSizeReq :: WidgetEnv s e -> WidgetInstance s e -> (SizeReq, SizeReq)
instUpdateSizeReq wenv inst = (sizeReqW,  sizeReqH) where
  widget = _wiWidget inst
  reqInst = widgetUpdateSizeReq widget wenv inst
  sizeReqW = _wiSizeReqW reqInst
  sizeReqH = _wiSizeReqH reqInst

instResize :: WidgetEnv s e -> Rect -> WidgetInstance s e -> WidgetInstance s e
instResize wenv viewport inst = newInst where
  reqInst = widgetUpdateSizeReq (_wiWidget inst) wenv inst
  newInst = widgetResize (_wiWidget reqInst) wenv viewport viewport reqInst

instGetEvents :: WidgetEnv s e -> SystemEvent -> WidgetInstance s e -> Seq e
instGetEvents wenv evt inst = events where
  widget = _wiWidget inst
  mtargetPath = getTargetPath wenv Nothing Nothing rootPath evt inst
  targetPath = fromMaybe rootPath mtargetPath
  result = widgetHandleEvent widget wenv targetPath evt inst
  events = maybe Seq.empty _wrEvents result

instRunEvent
  :: (Eq s)
  => WidgetEnv s e
  -> SystemEvent
  -> WidgetInstance s e
  -> HandlerStep s e
instRunEvent wenv evt inst = instRunEvents wenv [evt] inst

instRunEvents
  :: (Eq s)
  => WidgetEnv s e
  -> [SystemEvent]
  -> WidgetInstance s e
  -> HandlerStep s e
instRunEvents wenv evts inst = unsafePerformIO $ do
  let winSize = testWindowSize
  let useHdpi = True
  let dpr = 1
  let model = _weModel wenv
  let monomerContext = initMonomerContext model winSize useHdpi dpr
  let newInst = instInit wenv inst

  (step, ctx) <- runStateT (handleSystemEvents wenv evts newInst) monomerContext
  return step
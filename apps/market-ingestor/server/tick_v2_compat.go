// MD-001: market-ingestor compatibility translation to tick contract v2.
package server

import (
	v1 "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	mdv2 "github.com/Parsaeffatravesh/tragge/packages/contracts/marketdata/v2"
)

// TranslateLegacySnapshot converts a float v1 snapshot into canonical v2 ticks.
// Production Kafka topic cutover remains MD001-KAFKA-V2-CUTOVER.
func TranslateLegacySnapshot(snap v1.TickSnapshot, provider string, group mdv2.AssetGroup, epoch, startSeq int64) ([]mdv2.TickEvent, error) {
	return mdv2.FromV1Snapshot(snap, mdv2.CompatOptions{
		Provider:      provider,
		AssetGroup:    group,
		SourceEpoch:   epoch,
		StartSeq:      startSeq,
		EventIDPrefix: "ingestor",
	})
}

// NewGapEvent builds an explicit gap control event (silent drops prohibited).
func NewGapEvent(eventID, symbol string, group mdv2.AssetGroup, provider string, epoch, prevSeq, nextSeq, nowMS int64) (mdv2.FeedControlEvent, error) {
	missing := nextSeq - prevSeq - 1
	ev := mdv2.FeedControlEvent{
		SchemaVersion: mdv2.SchemaVersion,
		EventID:       eventID,
		Type:          mdv2.ControlGap,
		Symbol:        symbol,
		AssetGroup:    group,
		Provider:      provider,
		SourceEpoch:   epoch,
		PrevSequence:  prevSeq,
		NextSequence:  nextSeq,
		MissingCount:  missing,
		Reason:        "sequence_gap",
		OccurredAtMS:  nowMS,
	}
	return ev, ev.Validate()
}
